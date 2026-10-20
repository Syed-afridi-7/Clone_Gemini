use std::collections::HashMap;
use std::path::Path;
use std::process::Stdio;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::process::{ChildStdin, Command};
use tokio::sync::Mutex;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpServerConfig {
    pub command: String,
    #[serde(default)]
    pub args: Vec<String>,
    #[serde(default)]
    pub env: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct McpConfigFile {
    #[serde(rename = "mcpServers", default)]
    pub mcp_servers: HashMap<String, McpServerConfig>,
}

pub struct McpServerSession {
    pub server_name: String,
    stdin: Arc<Mutex<ChildStdin>>,
    next_id: AtomicU64,
    pending: Arc<Mutex<HashMap<u64, tokio::sync::oneshot::Sender<Value>>>>,
}

impl McpServerSession {
    pub async fn spawn(name: &str, config: &McpServerConfig, cwd: &Path) -> Result<Self> {
        let mut cmd = Command::new(&config.command);
        cmd.args(&config.args)
            .current_dir(cwd)
            .envs(&config.env)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::null());

        let mut child = cmd.spawn().map_err(|e| anyhow!("Failed to spawn MCP server '{}': {}", name, e))?;

        let stdin = child.stdin.take().ok_or_else(|| anyhow!("Failed to open MCP stdin"))?;
        let stdout = child.stdout.take().ok_or_else(|| anyhow!("Failed to open MCP stdout"))?;

        let pending: Arc<Mutex<HashMap<u64, tokio::sync::oneshot::Sender<Value>>>> =
            Arc::new(Mutex::new(HashMap::new()));
        let pending_clone = Arc::clone(&pending);

        // Spawn background reader for JSON-RPC messages
        tokio::spawn(async move {
            let mut reader = BufReader::new(stdout).lines();
            while let Ok(Some(line)) = reader.next_line().await {
                let trimmed = line.trim();
                if trimmed.is_empty() {
                    continue;
                }
                if let Ok(val) = serde_json::from_str::<Value>(trimmed) {
                    if let Some(id) = val["id"].as_u64() {
                        let mut map = pending_clone.lock().await;
                        if let Some(tx) = map.remove(&id) {
                            let _ = tx.send(val);
                        }
                    }
                }
            }
        });

        let session = Self {
            server_name: name.to_string(),
            stdin: Arc::new(Mutex::new(stdin)),
            next_id: AtomicU64::new(1),
            pending,
        };

        // Perform initialize handshake
        let init_res = session
            .send_request(
                "initialize",
                json!({
                    "protocolVersion": "2024-11-05",
                    "capabilities": {},
                    "clientInfo": {
                        "name": "gemini-desktop",
                        "version": "1.0.0"
                    }
                }),
            )
            .await?;

        if init_res.get("error").is_some() {
            return Err(anyhow!("MCP initialize error: {:?}", init_res["error"]));
        }

        // Send initialized notification
        session.send_notification("notifications/initialized", json!({})).await?;

        Ok(session)
    }

    pub async fn send_request(&self, method: &str, params: Value) -> Result<Value> {
        let id = self.next_id.fetch_add(1, Ordering::SeqCst);
        let req = json!({
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params
        });

        let (tx, rx) = tokio::sync::oneshot::channel();
        {
            let mut map = self.pending.lock().await;
            map.insert(id, tx);
        }

        let mut data = serde_json::to_string(&req)?;
        data.push('\n');

        {
            let mut stdin = self.stdin.lock().await;
            stdin.write_all(data.as_bytes()).await?;
            stdin.flush().await?;
        }

        let res = tokio::time::timeout(std::time::Duration::from_secs(15), rx)
            .await
            .map_err(|_| anyhow!("MCP request '{}' timed out", method))?
            .map_err(|_| anyhow!("MCP response channel closed"))?;

        Ok(res)
    }

    pub async fn send_notification(&self, method: &str, params: Value) -> Result<()> {
        let notif = json!({
            "jsonrpc": "2.0",
            "method": method,
            "params": params
        });
        let mut data = serde_json::to_string(&notif)?;
        data.push('\n');

        let mut stdin = self.stdin.lock().await;
        stdin.write_all(data.as_bytes()).await?;
        stdin.flush().await?;
        Ok(())
    }

    pub async fn list_tools(&self) -> Result<Vec<Value>> {
        let res = self.send_request("tools/list", json!({})).await?;
        if let Some(tools) = res["result"]["tools"].as_array() {
            let mut converted = Vec::new();
            for t in tools {
                let tool_name = t["name"].as_str().unwrap_or_default();
                let desc = t["description"].as_str().unwrap_or_default();
                let input_schema = &t["inputSchema"];

                converted.push(json!({
                    "type": "function",
                    "function": {
                        "name": format!("mcp_{}_{}", self.server_name, tool_name),
                        "description": format!("[MCP: {}] {}", self.server_name, desc),
                        "parameters": input_schema
                    }
                }));
            }
            Ok(converted)
        } else {
            Ok(vec![])
        }
    }

    pub async fn call_tool(&self, tool_name: &str, arguments: &Value) -> Result<String> {
        let res = self
            .send_request(
                "tools/call",
                json!({
                    "name": tool_name,
                    "arguments": arguments
                }),
            )
            .await?;

        if let Some(content_arr) = res["result"]["content"].as_array() {
            let mut out = String::new();
            for c in content_arr {
                if let Some(text) = c["text"].as_str() {
                    out.push_str(text);
                    out.push('\n');
                }
            }
            Ok(out.trim().to_string())
        } else {
            Ok(serde_json::to_string_pretty(&res["result"]).unwrap_or_default())
        }
    }
}

pub struct McpClient {
    sessions: Arc<Mutex<HashMap<String, McpServerSession>>>,
}

impl McpClient {
    pub fn new() -> Self {
        Self {
            sessions: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub async fn load_servers(&self, workspace_root: &Path) -> Result<usize> {
        let mut config = McpConfigFile::default();

        // 1. Check workspace .gemini/mcp.json or .gemini/mcp_servers.json
        let ws_config1 = workspace_root.join(".gemini").join("mcp.json");
        let ws_config2 = workspace_root.join(".gemini").join("mcp_servers.json");
        let path_to_load = if ws_config1.exists() {
            Some(ws_config1)
        } else if ws_config2.exists() {
            Some(ws_config2)
        } else {
            None
        };

        if let Some(path) = path_to_load {
            if let Ok(content) = std::fs::read_to_string(path) {
                if let Ok(parsed) = serde_json::from_str::<McpConfigFile>(&content) {
                    config.mcp_servers.extend(parsed.mcp_servers);
                }
            }
        }

        // 2. Check user home directory ~/.gemini/mcp_servers.json
        if let Ok(user_profile) = std::env::var("USERPROFILE") {
            let home_config = Path::new(&user_profile).join(".gemini").join("mcp_servers.json");
            if home_config.exists() {
                if let Ok(content) = std::fs::read_to_string(home_config) {
                    if let Ok(parsed) = serde_json::from_str::<McpConfigFile>(&content) {
                        for (k, v) in parsed.mcp_servers {
                            config.mcp_servers.entry(k).or_insert(v);
                        }
                    }
                }
            }
        }

        let mut count = 0;
        let mut sessions_map = self.sessions.lock().await;

        for (name, server_cfg) in config.mcp_servers {
            if !sessions_map.contains_key(&name) {
                if let Ok(session) = McpServerSession::spawn(&name, &server_cfg, workspace_root).await {
                    sessions_map.insert(name, session);
                    count += 1;
                }
            }
        }

        Ok(count)
    }

    pub async fn get_all_tools(&self) -> Vec<Value> {
        let sessions = self.sessions.lock().await;
        let mut tools = Vec::new();
        for session in sessions.values() {
            if let Ok(server_tools) = session.list_tools().await {
                tools.extend(server_tools);
            }
        }
        tools
    }

    pub async fn call_tool(&self, prefixed_name: &str, arguments: &Value) -> Result<String> {
        // Name format: mcp_{server_name}_{original_name}
        if !prefixed_name.starts_with("mcp_") {
            return Err(anyhow!("Not an MCP tool: {}", prefixed_name));
        }

        let rest = &prefixed_name[4..];
        let mut parts = rest.splitn(2, '_');
        let server_name = parts.next().ok_or_else(|| anyhow!("Invalid MCP tool format"))?;
        let tool_name = parts.next().ok_or_else(|| anyhow!("Invalid MCP tool format"))?;

        let sessions = self.sessions.lock().await;
        let session = sessions
            .get(server_name)
            .ok_or_else(|| anyhow!("MCP server '{}' not connected", server_name))?;

        session.call_tool(tool_name, arguments).await
    }
}

impl Default for McpClient {
    fn default() -> Self {
        Self::new()
    }
}
