use anyhow::{anyhow, Result};
use futures_util::StreamExt;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaModel {
    pub name: String,
    pub size: u64,
    pub modified_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaTagsResponse {
    pub models: Vec<OllamaModel>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolCallFunction {
    pub name: String,
    pub arguments: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolCall {
    pub function: ToolCallFunction,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaMessage {
    pub role: String,
    pub content: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tool_calls: Option<Vec<ToolCall>>,
}

#[derive(Debug, Clone)]
pub struct ChatResponse {
    pub content: String,
    pub tool_calls: Vec<ToolCall>,
}

pub struct OllamaClient {
    client: Client,
    base_url: String,
}

impl OllamaClient {
    pub fn new(base_url: &str) -> Self {
        Self {
            client: Client::builder().build().unwrap_or_default(),
            base_url: base_url.trim_end_matches('/').to_string(),
        }
    }

    pub async fn list_models(&self) -> Result<Vec<OllamaModel>> {
        let url = format!("{}/api/tags", self.base_url);
        let res = self.client.get(&url).send().await?;
        if !res.status().is_success() {
            return Err(anyhow!("Failed to list models: HTTP {}", res.status()));
        }
        let tags: OllamaTagsResponse = res.json().await?;
        Ok(tags.models)
    }

    pub async fn chat_stream<F>(
        &self,
        model: &str,
        messages: &[OllamaMessage],
        tools: &[Value],
        mut on_token: F,
    ) -> Result<ChatResponse>
    where
        F: FnMut(String) + Send + 'static,
    {
        let url = format!("{}/api/chat", self.base_url);
        let mut body = json!({
            "model": model,
            "messages": messages,
            "stream": true,
        });

        if !tools.is_empty() {
            body["tools"] = json!(tools);
        }

        let res = self.client.post(&url).json(&body).send().await?;
        if !res.status().is_success() {
            let error_text = res.text().await.unwrap_or_default();
            return Err(anyhow!("Ollama error ({}): {}", url, error_text));
        }

        let mut stream = res.bytes_stream();
        let mut accumulated_content = String::new();
        let mut accumulated_tool_calls: Vec<ToolCall> = Vec::new();
        let mut buffer = String::new();

        while let Some(chunk_result) = stream.next().await {
            let bytes = chunk_result?;
            let text = String::from_utf8_lossy(&bytes);
            buffer.push_str(&text);

            while let Some(pos) = buffer.find('\n') {
                let line = buffer[..pos].trim().to_string();
                buffer.drain(..=pos);

                if line.is_empty() {
                    continue;
                }

                if let Ok(val) = serde_json::from_str::<Value>(&line) {
                    if let Some(content_chunk) = val["message"]["content"].as_str() {
                        if !content_chunk.is_empty() {
                            accumulated_content.push_str(content_chunk);
                            on_token(content_chunk.to_string());
                        }
                    }

                    if let Some(tool_calls_arr) = val["message"]["tool_calls"].as_array() {
                        for tc_val in tool_calls_arr {
                            if let Ok(tc) = serde_json::from_value::<ToolCall>(tc_val.clone()) {
                                accumulated_tool_calls.push(tc);
                            }
                        }
                    }
                }
            }
        }

        Ok(ChatResponse {
            content: accumulated_content,
            tool_calls: accumulated_tool_calls,
        })
    }
}
