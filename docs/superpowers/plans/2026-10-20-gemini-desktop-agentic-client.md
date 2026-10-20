# Gemini Desktop Agentic Client — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Build a Tauri v2 desktop application in `E:\gemini-clone\desktop\` that provides a Google Gemini–faithful UI with a local agentic coding engine powered by Ollama, sandboxed filesystem access, terminal execution, and MCP extensibility.

**Architecture:** Tauri v2 with a Native Rust Agent Core (orchestrator, sandbox guard, process runner, MCP client) communicating over typed IPC with a React 19 + TypeScript + Tailwind CSS frontend that mirrors the Google Gemini Material 3 design system.

**Tech Stack:** Rust 1.80+, Tauri v2, React 19, TypeScript 5.5+, Vite 6, Tailwind CSS 4, Lucide React, reqwest (async HTTP), tokio (async runtime), similar (diff), dunce (path canonicalization), serde_json, @tauri-apps/api v2, @tauri-apps/plugin-dialog, diff2html (diff rendering), react-markdown + react-syntax-highlighter (code blocks), zustand (state management).

**Spec:** `E:\gemini-clone\docs\superpowers\specs\2026-10-20-gemini-desktop-agentic-client-design.md`

---

## Global Constraints

- Root: `E:\gemini-clone\desktop\` — new Tauri v2 + React 19 + Vite workspace.
- All filesystem access must go through `SandboxGuard` (strict `dunce::canonicalize` + `starts_with(workspace_root)` check).
- Ollama must be running locally at `http://localhost:11434` (not bundled — user installs separately).
- Google Gemini brand palette strictly applied: dark canvas `#131314`, surface `#1E1F20`, hover `#282A2C`, border `#3C4043`, gradient `#4285F4 → #9B72CB → #D96570`.
- `cargo test` and `npm run typecheck` must pass clean before each task is marked complete.

---

## Task 1: Project Scaffolding & Workspace Setup

**Files:**
- Create: `E:\gemini-clone\desktop\` (Tauri v2 project)
- Create: `desktop\src-tauri\Cargo.toml`
- Create: `desktop\vite.config.ts`
- Create: `desktop\src\main.tsx`
- Create: `desktop\src\App.tsx`
- Create: `desktop\src\index.css`

**Step 1: Scaffold Tauri v2 project**

Run from `E:\gemini-clone`:
```powershell
npm create tauri-app@latest desktop -- --template react-ts --manager npm
```
When prompted: App name = `gemini-desktop`, identifier = `com.geminiclone.desktop`.

**Step 2: Install Rust dependencies**

Edit `desktop\src-tauri\Cargo.toml` to add:
```toml
[dependencies]
tauri = { version = "2", features = ["protocol-asset"] }
tauri-plugin-dialog = "2"
tauri-plugin-shell = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tokio = { version = "1", features = ["full"] }
reqwest = { version = "0.12", features = ["json", "stream"] }
dunce = "1"
similar = "2"
uuid = { version = "1", features = ["v4"] }
thiserror = "1"
anyhow = "1"
futures-util = "0.3"
bytes = "1"

[dev-dependencies]
tempfile = "3"
tokio-test = "0.4"
```

**Step 3: Install frontend dependencies**

```powershell
cd E:\gemini-clone\desktop
npm install
npm install @tauri-apps/plugin-dialog lucide-react diff2html zustand uuid react-markdown react-syntax-highlighter
npm install -D @types/prismjs @types/react-syntax-highlighter @types/uuid tailwindcss @tailwindcss/vite
```

**Step 4: Configure Tailwind CSS v4 with Gemini design tokens**

Create `desktop\src\index.css`:
```css
@import "tailwindcss";

body {
  background-color: #131314;
  color: #E3E3E3;
  font-family: 'Google Sans', 'Outfit', 'Roboto', sans-serif;
  margin: 0;
  padding: 0;
}
```

**Step 5: Configure vite.config.ts**

```ts
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  clearScreen: false,
  server: { port: 1420, strictPort: true, host: false },
  envPrefix: ["VITE_", "TAURI_ENV_*"],
  build: {
    target: process.env.TAURI_ENV_PLATFORM === "windows" ? "chrome105" : "safari13",
    minify: !process.env.TAURI_ENV_DEBUG ? "esbuild" : false,
    sourcemap: !!process.env.TAURI_ENV_DEBUG,
  },
});
```

**Step 6: Verify project scaffolds**

```powershell
cd E:\gemini-clone\desktop\src-tauri
cargo check
```
Expected: 0 errors.

---

## Task 2: Rust Sandbox Guard (`sandbox` module)

**Files:**
- Create: `desktop\src-tauri\src\sandbox\mod.rs`
- Create: `desktop\src-tauri\src\sandbox\guard.rs`

**Step 1: Create module**

`desktop\src-tauri\src\sandbox\mod.rs`:
```rust
pub mod guard;
pub use guard::{SandboxGuard, SandboxError};
```

**Step 2: Implement SandboxGuard**

`desktop\src-tauri\src\sandbox\guard.rs`:
```rust
use std::path::{Path, PathBuf};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum SandboxError {
    #[error("Path '{0}' is outside the workspace boundary")]
    PathOutsideWorkspace(PathBuf),
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Invalid path structure")]
    InvalidPath,
}

#[derive(Debug, Clone)]
pub struct SandboxGuard {
    workspace_root: PathBuf,
}

impl SandboxGuard {
    pub fn new(root: &Path) -> Result<Self, SandboxError> {
        let canonical_root = dunce::canonicalize(root)?;
        Ok(Self { workspace_root: canonical_root })
    }

    pub fn workspace_root(&self) -> &Path {
        &self.workspace_root
    }

    pub fn validate(&self, target: &Path) -> Result<PathBuf, SandboxError> {
        let full = if target.is_absolute() {
            target.to_path_buf()
        } else {
            self.workspace_root.join(target)
        };

        let resolved = if full.exists() {
            dunce::canonicalize(&full)?
        } else {
            let parent = full.parent().ok_or(SandboxError::InvalidPath)?;
            let canon_parent = dunce::canonicalize(parent)?;
            let filename = full.file_name().ok_or(SandboxError::InvalidPath)?;
            canon_parent.join(filename)
        };

        if !resolved.starts_with(&self.workspace_root) {
            return Err(SandboxError::PathOutsideWorkspace(resolved));
        }

        Ok(resolved)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn allows_paths_inside_workspace() {
        let dir = tempdir().unwrap();
        let guard = SandboxGuard::new(dir.path()).unwrap();
        let result = guard.validate(Path::new("src/main.rs"));
        assert!(result.is_ok());
    }

    #[test]
    fn blocks_traversal_above_workspace() {
        let dir = tempdir().unwrap();
        let guard = SandboxGuard::new(dir.path()).unwrap();
        let result = guard.validate(Path::new("../../etc/passwd"));
        assert!(matches!(result, Err(SandboxError::PathOutsideWorkspace(_))));
    }

    #[test]
    fn blocks_absolute_path_outside_workspace() {
        let dir = tempdir().unwrap();
        let guard = SandboxGuard::new(dir.path()).unwrap();
        let outside = dir.path().parent().unwrap().join("evil.txt");
        let result = guard.validate(&outside);
        assert!(matches!(result, Err(SandboxError::PathOutsideWorkspace(_))));
    }
}
```

**Step 3: Run tests**

```powershell
cd E:\gemini-clone\desktop\src-tauri
cargo test sandbox -- --nocapture
```
Expected: 3/3 tests pass.

---

## Task 3: Process Runner (`terminal` module)

**Files:**
- Create: `desktop\src-tauri\src\terminal\mod.rs`
- Create: `desktop\src-tauri\src\terminal\runner.rs`

**Step 1: Create module**

`desktop\src-tauri\src\terminal\mod.rs`:
```rust
pub mod runner;
pub use runner::{ProcessRunner, CommandOutput, RunnerError};
```

**Step 2: Implement ProcessRunner**

`desktop\src-tauri\src\terminal\runner.rs`:
```rust
use std::path::Path;
use std::process::Stdio;
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::process::Command;
use tokio::sync::Mutex;
use tokio::time::{timeout, Duration};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum RunnerError {
    #[error("Timed out after {0}s")]
    Timeout(u64),
    #[error("Spawn failed: {0}")]
    SpawnError(String),
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
}

#[derive(Debug, Clone)]
pub struct CommandOutput {
    pub stdout: String,
    pub stderr: String,
    pub exit_code: i32,
}

pub struct ProcessRunner;

impl ProcessRunner {
    pub async fn run<F>(
        command_str: &str,
        cwd: &Path,
        timeout_secs: u64,
        on_stdout_chunk: F,
    ) -> Result<CommandOutput, RunnerError>
    where
        F: Fn(String) + Send + 'static,
    {
        let on_stdout_chunk = Arc::new(Mutex::new(on_stdout_chunk));

        #[cfg(target_os = "windows")]
        let mut child = Command::new("powershell.exe")
            .args(["-NoProfile", "-Command", command_str])
            .current_dir(cwd)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .map_err(|e| RunnerError::SpawnError(e.to_string()))?;

        #[cfg(not(target_os = "windows"))]
        let mut child = Command::new("bash")
            .args(["-c", command_str])
            .current_dir(cwd)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .map_err(|e| RunnerError::SpawnError(e.to_string()))?;

        let stdout_pipe = child.stdout.take().expect("stdout piped");
        let stderr_pipe = child.stderr.take().expect("stderr piped");

        let stdout_buf = Arc::new(Mutex::new(String::new()));
        let stderr_buf = Arc::new(Mutex::new(String::new()));

        let sb = Arc::clone(&stdout_buf);
        let cb = Arc::clone(&on_stdout_chunk);
        let t1 = tokio::spawn(async move {
            let mut lines = BufReader::new(stdout_pipe).lines();
            while let Ok(Some(line)) = lines.next_line().await {
                let s = format!("{}\n", line);
                sb.lock().await.push_str(&s);
                cb.lock().await(s);
            }
        });

        let eb = Arc::clone(&stderr_buf);
        let t2 = tokio::spawn(async move {
            let mut lines = BufReader::new(stderr_pipe).lines();
            while let Ok(Some(line)) = lines.next_line().await {
                eb.lock().await.push_str(&format!("{}\n", line));
            }
        });

        let result = timeout(Duration::from_secs(timeout_secs), child.wait()).await;
        let exit_code = match result {
            Err(_) => { let _ = child.kill().await; return Err(RunnerError::Timeout(timeout_secs)); }
            Ok(Err(e)) => return Err(RunnerError::Io(e)),
            Ok(Ok(s)) => s.code().unwrap_or(-1),
        };

        let _ = tokio::join!(t1, t2);
        Ok(CommandOutput {
            stdout: stdout_buf.lock().await.clone(),
            stderr: stderr_buf.lock().await.clone(),
            exit_code,
        })
    }
}
```

**Step 3: Compile check**

```powershell
cd E:\gemini-clone\desktop\src-tauri
cargo check
```
Expected: 0 errors.

---

## Task 4: Ollama Client, Tool Schemas & Approval Manager

**Files:**
- Create: `desktop\src-tauri\src\agent\mod.rs`
- Create: `desktop\src-tauri\src\agent\ollama_client.rs`
- Create: `desktop\src-tauri\src\agent\tools.rs`
- Create: `desktop\src-tauri\src\agent\approval.rs`

**Step 1: Create module**

`desktop\src-tauri\src\agent\mod.rs`:
```rust
pub mod ollama_client;
pub mod tools;
pub mod approval;
pub mod orchestrator;

pub use ollama_client::OllamaClient;
pub use approval::{ApprovalManager, ApprovalDecision};
```

**Step 2: OllamaClient** — see full implementation in Task 4 of spec design doc.

**Step 3: Tool schemas** — 6 tools: `read_file`, `write_file`, `apply_diff`, `run_command`, `list_directory`, `search_files` as defined in the spec.

**Step 4: ApprovalManager** — `tokio::sync::oneshot` channel map keyed by UUID `request_id`.

**Step 5: Compile check**

```powershell
cargo check
```
Expected: 0 errors.

---

## Task 5: Agent Orchestrator Loop & Tauri Commands

**Files:**
- Create: `desktop\src-tauri\src\agent\orchestrator.rs`
- Create: `desktop\src-tauri\src\mcp\mod.rs`
- Create: `desktop\src-tauri\src\mcp\client.rs` (stub)
- Modify: `desktop\src-tauri\src\main.rs`

**Tauri commands to register:**
- `list_ollama_models` → GET `/api/tags`
- `set_workspace` → stores workspace path in `AppState`
- `set_model` → stores selected model in `AppState`
- `send_agent_prompt` → spawns `AgentOrchestrator.run()` in `tokio::spawn`
- `approve_permission` → resolves oneshot channel via `ApprovalManager`

**Step 1: Implement orchestrator** — Max 20 tool iterations, 3-tier policy (read → auto, write → diff gate, run → command gate).

**Step 2: Wire main.rs** — register all 5 commands, init plugins.

**Step 3: Full compile check**

```powershell
cargo check
```
Expected: 0 errors.

---

## Task 6: React UI Shell, Zustand Store & Design System

**Files:**
- Create: `desktop\src\store\chatStore.ts`
- Create: `desktop\src\components\GeminiSparkle.tsx`
- Create: `desktop\src\components\AppHeader.tsx`
- Create: `desktop\src\components\WorkspaceBar.tsx`
- Create: `desktop\src\components\Sidebar.tsx`
- Modify: `desktop\src\App.tsx`

**Design Tokens Applied:**
- Canvas: `#131314`, Surface: `#1E1F20`, Hover: `#282A2C`, Border: `#3C4043`
- Gradient: `from-[#4285F4] via-[#9B72CB] to-[#D96570]`

**Step 1:** Zustand store with message list, workspace, model, agentRunning, ollamaModels, pendingApproval.

**Step 2:** GeminiSparkle SVG with 4-point gradient shape.

**Step 3:** AppHeader with model selector auto-populated from `list_ollama_models`.

**Step 4:** WorkspaceBar with native folder picker (`@tauri-apps/plugin-dialog`).

**Step 5: TypeScript check**

```powershell
npm run typecheck
```
Expected: 0 errors.

---

## Task 7: Chat Feed, Message Bubbles, Prompt Bar & Sidebar

**Files:**
- Create: `desktop\src\components\ChatArea.tsx`
- Create: `desktop\src\components\MessageBubble.tsx`
- Create: `desktop\src\components\ToolEventCard.tsx`
- Create: `desktop\src\components\PromptBar.tsx`
- Create: `desktop\src\hooks\useAgentEvents.ts`

**Step 1:** `useAgentEvents` hook — listens to 7 Tauri events: `agent:token`, `agent:done`, `agent:error`, `agent:diff_ready`, `agent:command_approval_request`, `agent:stdout`, `agent:tool_started`.

**Step 2:** `ToolEventCard` — compact tool chip (icon + path/command + status badge).

**Step 3:** `MessageBubble` — user pill (right-aligned, `#282A2C` bg) + assistant (left-aligned with sparkle avatar, ReactMarkdown + SyntaxHighlighter, streaming cursor blink).

**Step 4:** `PromptBar` — auto-growing textarea, send/stop button with gradient → red transition, attachment and mic icon buttons.

**Step 5:** `ChatArea` — scroll container with `useEffect` auto-scroll + Empty State "Hello, Human" gradient heading.

**Step 6: TypeScript check**

```powershell
npm run typecheck
```
Expected: 0 errors.

---

## Task 8: Diff Review Modal & Terminal Drawer

**Files:**
- Create: `desktop\src\components\DiffReviewModal.tsx`

**Step 1:** DiffReviewModal — `fixed inset-0 z-50` overlay, diff2html side-by-side renderer for file edits, command preview card for shell commands.

**Step 2:** Approve path calls `invoke("approve_permission", { requestId, approved: true })`.

**Step 3:** Reject path calls same command with `approved: false`.

**Step 4: TypeScript check**

```powershell
npm run typecheck
```
Expected: 0 errors.

---

## Task 9: MCP Stdio Client (Rust)

**Files:**
- Modify: `desktop\src-tauri\src\mcp\client.rs`

**Step 1:** Implement `McpClient::start()` — spawns stdio process, runs JSON-RPC `initialize` handshake, fetches `tools/list`.

**Step 2:** Implement `McpClient::call_tool()` — sends `tools/call` JSON-RPC message and returns result.

**Step 3: Compile check**

```powershell
cargo check
```
Expected: 0 errors.

---

## Task 10: End-to-End Build & Smoke Test

**Step 1: Full Rust test suite**

```powershell
cd E:\gemini-clone\desktop\src-tauri
cargo test -- --nocapture
```
Expected: All tests pass (3+ sandbox tests).

**Step 2: TypeScript typecheck**

```powershell
cd E:\gemini-clone\desktop
npm run typecheck
```
Expected: 0 errors.

**Step 3: Dev mode launch**

```powershell
cd E:\gemini-clone\desktop
npm run tauri dev
```
Expected: Tauri desktop window opens, dark Gemini canvas visible.

**Step 4: Manual smoke test**

Pre-conditions: Ollama running (`ollama serve`), model pulled (`ollama pull qwen2.5-coder:7b`).

1. Select workspace folder via native picker.
2. Verify model dropdown shows installed Ollama models.
3. Send: *"List all files in this project"* → verify `list_directory` chips appear with no approval modal.
4. Send: *"Add a comment at the top of the main file"* → verify Diff Review Modal appears, approve, verify file is edited.
5. Send: *"Run echo Hello from Gemini Desktop"* → verify Command Approval Modal appears, approve, verify stdout streams in chat.
6. Verify Stop button kills a running process immediately.

**Step 5: Final commit**

```powershell
cd E:\gemini-clone
git add .
git commit -m "feat(desktop): complete Gemini Desktop agentic client v1.0"
```
