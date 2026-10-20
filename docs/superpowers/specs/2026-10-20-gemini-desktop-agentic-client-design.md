# Google Gemini Desktop Client: Architecture Blueprint & Agentic Coding Specification

**Document Version:** 1.0.0  
**Status:** Approved by User  
**Date:** 2026-10-20  
**Target Platform:** Desktop (Windows, macOS, Linux via Tauri v2) with Shared Architecture for Web  
**Primary Engine:** Local LLM via Ollama (`qwen2.5-coder`, `llama3.1`, etc.)  
**Workspace:** `E:\gemini-clone\desktop`  

---

## 1. Executive Summary & Goals

This specification details the architecture and technical design of **Gemini Desktop**, a desktop-first client faithfully mirroring Google Gemini's visual design while introducing autonomous, local agentic coding capabilities.

### Core Capabilities
1. **Zero-Cloud Local Intelligence:** Connects directly to a local [Ollama](https://ollama.com) instance (`http://localhost:11434`), supporting coding models (e.g. `qwen2.5-coder:7b/14b/32b`, `llama3.1:8b`) with native JSON function calling and zero API subscription costs.
2. **Local Workspace Grounding:** The user selects any local directory on their system as an active workspace.
3. **Agentic Tool Calling:** The model autonomously reads codebase files, navigates directories, computes and applies edits, and runs build/test shell commands inside the chosen project.
4. **Sandboxed Security & Human-in-the-Loop:** Strict filesystem sandboxing prevents path traversal outside the project directory. File edits display interactive visual diffs for approval, and terminal commands require user consent with an emergency process kill-switch.
5. **Model Context Protocol (MCP) Host:** Extensible architecture in Rust that spawns stdio MCP servers (e.g., Git, PostgreSQL, Docker) to augment the model's tool capabilities.

---

## 2. System Architecture

The application is structured into two primary tiers communicating over Tauri v2's asynchronous IPC bridge:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        TAURI V2 DESKTOP CLIENT                         │
│                                                                        │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │       React 19 + TypeScript + Tailwind Presentation Layer      │   │
│   │                                                                │   │
│   │  * Google Gemini Material 3 Theme (Dark/Light + Gradients)     │   │
│   │  * "Gemini Code" / Workspace Selector (Native Folder Picker)   │   │
│   │  * Chat Feed with Live Token Streaming & Markdown Rendering    │   │
│   │  * Interactive Diff Review Modal (Additions / Deletions)       │   │
│   │  * Live Terminal Execution Drawer (Streaming stdout/stderr)    │   │
│   │  * Ollama Model Selector (/api/tags discovery)                 │   │
│   └───────────────────────────────┬────────────────────────────────┘   │
│                                   │ Tauri IPC Commands & Events        │
│                                   ▼                                    │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │               Native Rust Agent Core (src-tauri)               │   │
│   │                                                                │   │
│   │  * Agent Loop Orchestrator (Multi-turn tool-calling state)     │   │
│   │  * Ollama HTTP Client (Streaming SSE parser for /api/chat)     │   │
│   │  * SandboxGuard (Dunce path canonicalization & prefix check)   │   │
│   │  * ProcessRunner (Shell spawning, stdout piping, kill-switch)  │   │
│   │  * McpHost (Stdio JSON-RPC 2.0 client for external MCP servers)│   │
│   │  * ApprovalManager (tokio::sync::oneshot pause/resume channels)│   │
│   └───────────────────────────────┬────────────────────────────────┘   │
└───────────────────────────────────┼────────────────────────────────────┘
                                    │
               ┌────────────────────┴────────────────────┐
               ▼                                         ▼
┌──────────────────────────────┐        ┌────────────────────────────────┐
│        Ollama Server         │        │    Local Project Workspace     │
│    http://localhost:11434    │        │  (User-selected directory)     │
│   qwen2.5-coder / llama3.1   │        │   Filesystem & Shell Execution │
└──────────────────────────────┘        └────────────────────────────────┘
```

---

## 3. Native Rust Agent Core (`src-tauri/src/`)

### 3.1. Modules Directory Layout
```
desktop/src-tauri/src/
├── main.rs                   # Tauri application entrypoint and command registry
├── agent/
│   ├── mod.rs                # Public agent interfaces
│   ├── orchestrator.rs       # Multi-turn tool execution loop
│   ├── ollama_client.rs      # Reqwest streaming client for Ollama API
│   ├── tools.rs              # Tool definitions and JSON schemas
│   └── approval.rs           # Channel-based human-in-the-loop approval manager
├── sandbox/
│   ├── mod.rs
│   └── guard.rs              # Path canonicalization and directory boundary validation
├── terminal/
│   ├── mod.rs
│   └── runner.rs             # Process spawn, stdout line reader, kill-switch
└── mcp/
    ├── mod.rs
    └── client.rs             # Stdio JSON-RPC 2.0 MCP protocol host
```

### 3.2. SandboxGuard & Path Security
To prevent malicious or unintended path traversal (`../`, absolute roots, symbolic link attacks), every file operation passes through `SandboxGuard`:

```rust
use std::path::{Path, PathBuf};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum SandboxError {
    #[error("Target path is outside the designated workspace: {0}")]
    PathOutsideWorkspace(PathBuf),
    #[error("Invalid path or directory not found: {0}")]
    IoError(#[from] std::io::Error),
    #[error("Invalid path structure")]
    InvalidPath,
}

pub struct SandboxGuard {
    workspace_root: PathBuf,
}

impl SandboxGuard {
    pub fn new(root: PathBuf) -> Result<Self, SandboxError> {
        let canonical_root = dunce::canonicalize(&root)?;
        Ok(Self { workspace_root: canonical_root })
    }

    pub fn validate_path(&self, target: &Path) -> Result<PathBuf, SandboxError> {
        let full_path = if target.is_absolute() {
            target.to_path_buf()
        } else {
            self.workspace_root.join(target)
        };

        let resolved = if full_path.exists() {
            dunce::canonicalize(&full_path)?
        } else {
            let parent = full_path.parent().ok_or(SandboxError::InvalidPath)?;
            let canonical_parent = dunce::canonicalize(parent)?;
            canonical_parent.join(full_path.file_name().ok_or(SandboxError::InvalidPath)?)
        };

        if !resolved.starts_with(&self.workspace_root) {
            return Err(SandboxError::PathOutsideWorkspace(resolved));
        }

        Ok(resolved)
    }

    pub fn workspace_root(&self) -> &Path {
        &self.workspace_root
    }
}
```

### 3.3. 3-Tier Security Policy & Approval Channels
1. **Tier 1 (Safe Reads):** `read_file`, `list_directory`, `search_files` execute immediately without halting the loop.
2. **Tier 2 (File Edits/Creates):** `write_file`, `apply_diff` calculate a unified diff using the `similar` crate and emit an `agent:diff_ready` event to the webview. The agent loop waits on a `tokio::sync::oneshot::Receiver<bool>`.
3. **Tier 3 (Shell Commands):** `run_command` emits an `agent:command_approval_request` event. The loop waits for the user's approval before spawning the process.

---

## 4. Built-In Coding Tool Schemas

The Rust backend supplies the following JSON schemas to Ollama via `tools` in the `/api/chat` request:

1. **`read_file`**: Read file content with optional start line and line limit.
2. **`apply_diff`**: Precise string target replacement in an existing file.
3. **`write_file`**: Full file write or creation.
4. **`run_command`**: Execute a shell command (`powershell.exe` on Windows, `bash` on macOS/Linux) with timeout and live stdout/stderr event streaming.
5. **`list_directory`**: List workspace directory structure.
6. **`search_files`**: Text or regex search across workspace files.

---

## 5. Model Context Protocol (MCP) Integration

The desktop app reads an optional MCP config from `~/.gemini/mcp_servers.json` or `.gemini/mcp.json` inside the workspace:

```json
{
  "mcpServers": {
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"]
    }
  }
}
```

- Rust's `McpClient` launches the process over `stdio`.
- Implements standard JSON-RPC 2.0 messages:
  - `{"jsonrpc": "2.0", "method": "initialize", "params": {...}}`
  - `{"jsonrpc": "2.0", "method": "tools/list"}`
  - `{"jsonrpc": "2.0", "method": "tools/call", "params": {...}}`
- All MCP tools are prefixed and exposed to Ollama dynamically.

---

## 6. Frontend Presentation Layer (`desktop/src/`)

### 6.1. Tech Stack
- **Framework:** React 19 + TypeScript + Vite
- **Styling:** Tailwind CSS + PostCSS (configured with Gemini brand colors)
- **Icons:** Lucide React
- **Syntax Highlighting & Diffs:** `prismjs` / `diff2html` / custom Material 3 diff renderer
- **Tauri API:** `@tauri-apps/api` v2, `@tauri-apps/plugin-dialog`

### 6.2. Gemini Design System
- **Dark Background:** `#131314`
- **Surface / Sidebar:** `#1E1F20`
- **Hover / Secondary:** `#282A2C`
- **Borders:** `#3C4043`
- **Signature Gradient:** Linear gradient `#4285F4` (Blue) → `#9B72CB` (Purple) → `#D96570` (Coral)
- **Typography:** Google Sans / Outfit / Roboto fallbacks

### 6.3. Key Views & UI Components
1. **Workspace Header:** Shows current project path, git branch, Ollama status badge, and model selector.
2. **Interactive Diff Review Modal:** Displays side-by-side or unified green/red diff with "Approve" (`Ctrl+Enter`) and "Reject" buttons.
3. **Live Terminal Drawer:** Bottom collapsible panel rendering streaming stdout/stderr with execution timer and "Stop" button.
4. **Tool Execution Steps:** Interactive chips in the chat bubble showing real-time tool progress (e.g. `✔ read_file: src/main.rs (45 lines)`).

---

## 7. Rollout & Implementation Plan

The rollout is structured into 4 sequential phases:

### Phase 1: Workspace Scaffolding & Native Rust Core
- Scaffold `desktop/` with Tauri v2 + React 19 + Vite.
- Implement `SandboxGuard` with dunce path validation and unit tests.
- Implement `ProcessRunner` with process spawning, stdout event streaming, and process termination.

### Phase 2: Ollama Streaming & Tool-Calling Engine
- Implement `OllamaClient` in Rust (`/api/tags` and `/api/chat` with SSE parsing).
- Implement the `AgentOrchestrator` multi-turn loop.
- Wire native coding tools (`read_file`, `write_file`, `apply_diff`, `run_command`, `list_directory`, `search_files`).
- Implement `ApprovalManager` for async UI confirmation.

### Phase 3: Gemini UI & Coding Workspace Features
- Build Google Gemini dark/light UI in React with Tailwind CSS.
- Build Workspace Picker with native folder dialog.
- Build Interactive Diff Review modal/card.
- Build Live Terminal Drawer with streaming logs and kill-switch.
- Build Tool Execution Timeline cards.

### Phase 4: Stdio MCP Host & Final Verification
- Implement `McpClient` for stdio JSON-RPC MCP server connections.
- End-to-end integration test: Launch desktop app -> select local project -> ask agent to create a feature and run tests -> verify autonomous loop with human approval.
- Produce walkthrough documentation.
