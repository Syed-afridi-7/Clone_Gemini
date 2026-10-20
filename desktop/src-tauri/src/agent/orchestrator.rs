use std::path::{Path, PathBuf};
use std::sync::Arc;
use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use similar::{ChangeTag, TextDiff};
use tauri::{AppHandle, Emitter};
use uuid::Uuid;

use crate::agent::approval::{ApprovalDecision, ApprovalManager};
use crate::agent::ollama_client::{OllamaClient, OllamaMessage};
use crate::agent::tools::get_tool_schemas;
use crate::mcp::McpClient;
use crate::sandbox::SandboxGuard;
use crate::terminal::ProcessRunner;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiffReadyPayload {
    pub request_id: String,
    pub file_path: String,
    pub original_content: String,
    pub new_content: String,
    pub unified_diff: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommandApprovalPayload {
    pub request_id: String,
    pub command: String,
    pub cwd: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolStartedPayload {
    pub tool_name: String,
    pub detail: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StdoutPayload {
    pub text: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenPayload {
    pub token: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ErrorPayload {
    pub error: String,
}

pub struct AgentOrchestrator {
    ollama: Arc<OllamaClient>,
    approval_mgr: Arc<ApprovalManager>,
    mcp: Arc<McpClient>,
}

impl AgentOrchestrator {
    pub fn new(
        ollama: Arc<OllamaClient>,
        approval_mgr: Arc<ApprovalManager>,
        mcp: Arc<McpClient>,
    ) -> Self {
        Self {
            ollama,
            approval_mgr,
            mcp,
        }
    }

    pub async fn run(
        &self,
        app: AppHandle,
        workspace_root: PathBuf,
        model: String,
        user_prompt: String,
    ) -> Result<()> {
        let guard = SandboxGuard::new(&workspace_root)
            .map_err(|e| anyhow!("Failed to initialize sandbox: {}", e))?;

        // Discover and load MCP servers if configured
        let _ = self.mcp.load_servers(&workspace_root).await;

        let mut conversation: Vec<OllamaMessage> = vec![
            OllamaMessage {
                role: "system".to_string(),
                content: format!(
                    "You are an expert autonomous software engineer operating inside the workspace: {}. \
                    You have access to tools to read, write, diff, search files, and run shell commands. \
                    Always inspect relevant files before modifying them. \
                    Keep edits targeted and explain your actions clearly.",
                    workspace_root.display()
                ),
                tool_calls: None,
            },
            OllamaMessage {
                role: "user".to_string(),
                content: user_prompt,
                tool_calls: None,
            },
        ];

        let mut tool_schemas = get_tool_schemas();
        let mcp_tools = self.mcp.get_all_tools().await;
        tool_schemas.extend(mcp_tools);

        let max_iterations = 20;

        for _iteration in 0..max_iterations {
            let app_handle = app.clone();
            let chat_res = self
                .ollama
                .chat_stream(
                    &model,
                    &conversation,
                    &tool_schemas,
                    move |token| {
                        let _ = app_handle.emit("agent:token", TokenPayload { token });
                    },
                )
                .await?;

            conversation.push(OllamaMessage {
                role: "assistant".to_string(),
                content: chat_res.content.clone(),
                tool_calls: if chat_res.tool_calls.is_empty() {
                    None
                } else {
                    Some(chat_res.tool_calls.clone())
                },
            });

            if chat_res.tool_calls.is_empty() {
                // Agent finished generating and has no tool calls
                break;
            }

            // Execute each tool call
            for tool_call in chat_res.tool_calls {
                let name = &tool_call.function.name;
                let args = &tool_call.function.arguments;

                let tool_output = self
                    .execute_tool(&app, &guard, name, args)
                    .await;

                conversation.push(OllamaMessage {
                    role: "tool".to_string(),
                    content: match tool_output {
                        Ok(out) => out,
                        Err(err) => format!("Error executing {}: {}", name, err),
                    },
                    tool_calls: None,
                });
            }
        }

        let _ = app.emit("agent:done", ());
        Ok(())
    }

    async fn execute_tool(
        &self,
        app: &AppHandle,
        guard: &SandboxGuard,
        name: &str,
        args: &Value,
    ) -> Result<String> {
        if name.starts_with("mcp_") {
            let _ = app.emit(
                "agent:tool_started",
                ToolStartedPayload {
                    tool_name: name.to_string(),
                    detail: serde_json::to_string(args).unwrap_or_default(),
                },
            );
            return self.mcp.call_tool(name, args).await;
        }

        match name {
            "read_file" => {
                let path_str = args["path"].as_str().ok_or_else(|| anyhow!("Missing 'path'"))?;
                let start_line = args["start_line"].as_u64();
                let line_limit = args["line_limit"].as_u64();

                let _ = app.emit(
                    "agent:tool_started",
                    ToolStartedPayload {
                        tool_name: name.to_string(),
                        detail: path_str.to_string(),
                    },
                );

                let safe_path = guard.validate(Path::new(path_str))?;
                let content = std::fs::read_to_string(&safe_path)?;

                if start_line.is_none() && line_limit.is_none() {
                    Ok(content)
                } else {
                    let lines: Vec<&str> = content.lines().collect();
                    let start = start_line.map(|s| s.saturating_sub(1) as usize).unwrap_or(0);
                    let limit = line_limit.map(|l| l as usize).unwrap_or(lines.len());
                    let end = (start + limit).min(lines.len());
                    let slice = lines[start..end].join("\n");
                    Ok(slice)
                }
            }

            "write_file" => {
                let path_str = args["path"].as_str().ok_or_else(|| anyhow!("Missing 'path'"))?;
                let content = args["content"].as_str().ok_or_else(|| anyhow!("Missing 'content'"))?;

                let safe_path = guard.validate(Path::new(path_str))?;
                let original_content = if safe_path.exists() {
                    std::fs::read_to_string(&safe_path).unwrap_or_default()
                } else {
                    String::new()
                };

                let diff_text = compute_diff(&original_content, content);
                let request_id = Uuid::new_v4().to_string();

                let _ = app.emit(
                    "agent:diff_ready",
                    DiffReadyPayload {
                        request_id: request_id.clone(),
                        file_path: path_str.to_string(),
                        original_content: original_content.clone(),
                        new_content: content.to_string(),
                        unified_diff: diff_text,
                    },
                );

                let rx = self.approval_mgr.create_request(request_id);
                let decision = rx.await.map_err(|_| anyhow!("Approval request cancelled"))?;

                match decision {
                    ApprovalDecision::Approved => {
                        guard.write_file(Path::new(path_str), content)?;
                        Ok(format!("Successfully wrote file '{}'", path_str))
                    }
                    ApprovalDecision::Rejected => {
                        Ok(format!("User rejected changes to '{}'", path_str))
                    }
                }
            }

            "apply_diff" => {
                let path_str = args["path"].as_str().ok_or_else(|| anyhow!("Missing 'path'"))?;
                let target = args["target"].as_str().ok_or_else(|| anyhow!("Missing 'target'"))?;
                let replacement = args["replacement"]
                    .as_str()
                    .ok_or_else(|| anyhow!("Missing 'replacement'"))?;

                let safe_path = guard.validate(Path::new(path_str))?;
                let original_content = std::fs::read_to_string(&safe_path)?;

                if !original_content.contains(target) {
                    return Err(anyhow!("Target snippet not found in '{}'", path_str));
                }

                let new_content = original_content.replace(target, replacement);
                let diff_text = compute_diff(&original_content, &new_content);
                let request_id = Uuid::new_v4().to_string();

                let _ = app.emit(
                    "agent:diff_ready",
                    DiffReadyPayload {
                        request_id: request_id.clone(),
                        file_path: path_str.to_string(),
                        original_content: original_content.clone(),
                        new_content: new_content.clone(),
                        unified_diff: diff_text,
                    },
                );

                let rx = self.approval_mgr.create_request(request_id);
                let decision = rx.await.map_err(|_| anyhow!("Approval request cancelled"))?;

                match decision {
                    ApprovalDecision::Approved => {
                        guard.write_file(Path::new(path_str), &new_content)?;
                        Ok(format!("Successfully applied diff to '{}'", path_str))
                    }
                    ApprovalDecision::Rejected => {
                        Ok(format!("User rejected diff to '{}'", path_str))
                    }
                }
            }

            "run_command" => {
                let command_str = args["command"].as_str().ok_or_else(|| anyhow!("Missing 'command'"))?;
                let timeout_secs = args["timeout_secs"].as_u64().unwrap_or(60);

                let request_id = Uuid::new_v4().to_string();
                let _ = app.emit(
                    "agent:command_approval_request",
                    CommandApprovalPayload {
                        request_id: request_id.clone(),
                        command: command_str.to_string(),
                        cwd: guard.workspace_root().display().to_string(),
                    },
                );

                let rx = self.approval_mgr.create_request(request_id);
                let decision = rx.await.map_err(|_| anyhow!("Command approval cancelled"))?;

                match decision {
                    ApprovalDecision::Approved => {
                        let _ = app.emit(
                            "agent:tool_started",
                            ToolStartedPayload {
                                tool_name: "run_command".to_string(),
                                detail: command_str.to_string(),
                            },
                        );

                        let app_clone = app.clone();
                        let output = ProcessRunner::run(
                            command_str,
                            guard.workspace_root(),
                            timeout_secs,
                            move |chunk| {
                                let _ = app_clone.emit("agent:stdout", StdoutPayload { text: chunk });
                            },
                        )
                        .await?;

                        Ok(format!(
                            "Exit Code: {}\nStdout:\n{}\nStderr:\n{}",
                            output.exit_code, output.stdout, output.stderr
                        ))
                    }
                    ApprovalDecision::Rejected => {
                        Ok(format!("User rejected execution of command: '{}'", command_str))
                    }
                }
            }

            "list_directory" => {
                let path_str = args["path"].as_str().unwrap_or("");
                let _ = app.emit(
                    "agent:tool_started",
                    ToolStartedPayload {
                        tool_name: name.to_string(),
                        detail: if path_str.is_empty() { "workspace root".to_string() } else { path_str.to_string() },
                    },
                );

                let target_path = if path_str.is_empty() || path_str == "." {
                    guard.workspace_root().to_path_buf()
                } else {
                    guard.validate(Path::new(path_str))?
                };

                let mut entries = Vec::new();
                for entry in std::fs::read_dir(&target_path)? {
                    if let Ok(e) = entry {
                        let file_name = e.file_name().to_string_lossy().to_string();
                        let file_type = if e.path().is_dir() { "dir" } else { "file" };
                        entries.push(format!("{}: {}", file_type, file_name));
                    }
                }
                entries.sort();
                Ok(entries.join("\n"))
            }

            "search_files" => {
                let query = args["query"].as_str().ok_or_else(|| anyhow!("Missing 'query'"))?;
                let sub_path = args["path"].as_str().unwrap_or("");

                let search_root = if sub_path.is_empty() || sub_path == "." {
                    guard.workspace_root().to_path_buf()
                } else {
                    guard.validate(Path::new(sub_path))?
                };

                let _ = app.emit(
                    "agent:tool_started",
                    ToolStartedPayload {
                        tool_name: name.to_string(),
                        detail: format!("query: '{}'", query),
                    },
                );

                let mut results = Vec::new();
                search_files_recursive(&search_root, query, &mut results, 0, 10);

                if results.is_empty() {
                    Ok(format!("No occurrences of '{}' found.", query))
                } else {
                    Ok(results.join("\n"))
                }
            }

            _ => Err(anyhow!("Unknown tool: {}", name)),
        }
    }
}

fn compute_diff(old: &str, new: &str) -> String {
    let diff = TextDiff::from_lines(old, new);
    let mut output = String::new();
    for change in diff.iter_all_changes() {
        let sign = match change.tag() {
            ChangeTag::Delete => "-",
            ChangeTag::Insert => "+",
            ChangeTag::Equal => " ",
        };
        output.push_str(&format!("{}{}", sign, change));
    }
    output
}

fn search_files_recursive(
    dir: &Path,
    query: &str,
    results: &mut Vec<String>,
    depth: usize,
    max_depth: usize,
) {
    if depth > max_depth || results.len() >= 50 {
        return;
    }

    let entries = match std::fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return,
    };

    for entry in entries.flatten() {
        let path = entry.path();
        let name = entry.file_name().to_string_lossy().to_string();

        if path.is_dir() {
            if name.starts_with('.')
                || name == "node_modules"
                || name == "target"
                || name == "dist"
                || name == "build"
            {
                continue;
            }
            search_files_recursive(&path, query, results, depth + 1, max_depth);
        } else if path.is_file() {
            if let Ok(metadata) = entry.metadata() {
                if metadata.len() > 1_000_000 {
                    continue; // Skip files > 1MB
                }
            }
            if let Ok(content) = std::fs::read_to_string(&path) {
                for (line_idx, line) in content.lines().enumerate() {
                    if line.contains(query) {
                        results.push(format!("{}:{}: {}", path.display(), line_idx + 1, line.trim()));
                        if results.len() >= 50 {
                            return;
                        }
                    }
                }
            }
        }
    }
}
