pub mod sandbox;
pub mod terminal;
pub mod agent;
pub mod mcp;

use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use serde::{Deserialize, Serialize};
use tauri::{AppHandle, Emitter, State};

use agent::{AgentOrchestrator, ApprovalDecision, ApprovalManager, OllamaClient};
use agent::ollama_client::OllamaTagsResponse;
use mcp::McpClient;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileNode {
    pub name: String,
    pub path: String,
    pub is_dir: bool,
    pub children: Option<Vec<FileNode>>,
}

pub struct AppState {
    pub workspace: Arc<Mutex<Option<PathBuf>>>,
    pub model: Arc<Mutex<String>>,
    pub approval_mgr: Arc<ApprovalManager>,
    pub ollama: Arc<OllamaClient>,
    pub mcp: Arc<McpClient>,
}

#[tauri::command]
async fn list_ollama_models(state: State<'_, AppState>) -> Result<OllamaTagsResponse, String> {
    let models = state.ollama.list_models().await.map_err(|e| e.to_string())?;
    Ok(OllamaTagsResponse { models })
}

#[tauri::command]
fn set_workspace(state: State<'_, AppState>, path: String) -> Result<(), String> {
    let p = PathBuf::from(path);
    *state.workspace.lock().unwrap() = Some(p);
    Ok(())
}

#[tauri::command]
fn set_model(state: State<'_, AppState>, model: String) -> Result<(), String> {
    *state.model.lock().unwrap() = model;
    Ok(())
}

fn scan_dir_recursive(root: &Path, dir: &Path, depth: u32, max_depth: u32) -> Vec<FileNode> {
    if depth > max_depth {
        return Vec::new();
    }

    let entries = match std::fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return Vec::new(),
    };

    let mut dir_entries: Vec<_> = entries.flatten().collect();
    dir_entries.sort_by(|a, b| {
        let a_is_dir = a.file_type().map(|t| t.is_dir()).unwrap_or(false);
        let b_is_dir = b.file_type().map(|t| t.is_dir()).unwrap_or(false);
        if a_is_dir != b_is_dir {
            b_is_dir.cmp(&a_is_dir)
        } else {
            a.file_name().cmp(&b.file_name())
        }
    });

    let mut nodes = Vec::new();
    for entry in dir_entries {
        let path = entry.path();
        let name = entry.file_name().to_string_lossy().to_string();

        if name.starts_with('.')
            || name == "node_modules"
            || name == "target"
            || name == "dist"
            || name == "build"
            || name == ".dart_tool"
        {
            continue;
        }

        let is_dir = entry.file_type().map(|t| t.is_dir()).unwrap_or(false);
        let relative_path = path
            .strip_prefix(root)
            .unwrap_or(&path)
            .to_string_lossy()
            .replace('\\', "/");

        let children = if is_dir {
            Some(scan_dir_recursive(root, &path, depth + 1, max_depth))
        } else {
            None
        };

        nodes.push(FileNode {
            name,
            path: relative_path,
            is_dir,
            children,
        });
    }

    nodes
}

#[tauri::command]
fn get_directory_tree(state: State<'_, AppState>) -> Result<Vec<FileNode>, String> {
    let workspace = state.workspace.lock().unwrap().clone();
    let workspace_root = workspace.ok_or_else(|| "No workspace folder selected".to_string())?;

    let tree = scan_dir_recursive(&workspace_root, &workspace_root, 0, 4);
    Ok(tree)
}

#[tauri::command]
async fn send_agent_prompt(
    app: AppHandle,
    state: State<'_, AppState>,
    prompt: String,
) -> Result<(), String> {
    let workspace = state.workspace.lock().unwrap().clone();
    let workspace_root = workspace.ok_or_else(|| "No workspace folder selected".to_string())?;

    let model = state.model.lock().unwrap().clone();
    if model.is_empty() {
        return Err("No Ollama model selected".to_string());
    }

    let orchestrator = AgentOrchestrator::new(
        Arc::clone(&state.ollama),
        Arc::clone(&state.approval_mgr),
        Arc::clone(&state.mcp),
    );

    tokio::spawn(async move {
        if let Err(err) = orchestrator.run(app.clone(), workspace_root, model, prompt).await {
            let _ = app.emit(
                "agent:error",
                agent::orchestrator::ErrorPayload {
                    error: err.to_string(),
                },
            );
        }
    });

    Ok(())
}

#[tauri::command]
fn approve_permission(
    state: State<'_, AppState>,
    request_id: String,
    approved: bool,
) -> Result<(), String> {
    let decision = if approved {
        ApprovalDecision::Approved
    } else {
        ApprovalDecision::Rejected
    };

    if state.approval_mgr.resolve(&request_id, decision) {
        Ok(())
    } else {
        Err(format!("Request '{}' not found or already resolved", request_id))
    }
}

pub fn run() {
    let app_state = AppState {
        workspace: Arc::new(Mutex::new(None)),
        model: Arc::new(Mutex::new(String::new())),
        approval_mgr: Arc::new(ApprovalManager::new()),
        ollama: Arc::new(OllamaClient::new("http://localhost:11434")),
        mcp: Arc::new(McpClient::new()),
    };

    tauri::Builder::default()
        .manage(app_state)
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![
            list_ollama_models,
            set_workspace,
            set_model,
            get_directory_tree,
            send_agent_prompt,
            approve_permission,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
