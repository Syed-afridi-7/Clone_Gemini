# Clone_Gemini

An open-source Google Gemini clone featuring a Flutter multi-platform UI and a desktop-first Tauri v2 agentic coding client powered by local Ollama LLMs with **Gemini Cowork** local workspace control.

---

## 🌟 Highlights

- **Gemini Cowork & Code Workspace (`desktop/`)**: Borrowed from Claude Cowork / Claude Code and redesigned in Google Gemini's signature Material 3 style:
  - **Mode Selector**: Toggle effortlessly between general **💬 Gemini Chat** and project-grounded **⚡ Gemini Cowork**.
  - **Collapsible Project File Drawer**: Recursive file/folder tree view, search filtering, and quick path referencing.
  - **Autonomous Coding Engine**: Local Ollama function calling to inspect files, propose targeted diffs, and run shell commands in the project directory.
  - **Interactive Diff Review Modal**: Visual unified/side-by-side diff review (`diff2html`) with keyboard shortcuts (`Ctrl+Enter` to approve, `Esc` to reject).
  - **Stdio MCP Host**: Connects to Model Context Protocol servers for Git, databases, and external tools.
- **Flutter Cross-Platform Frontend (`frontend/`)**: Material 3 faithful Gemini interface with adaptive shell (mobile, tablet, desktop, web), dark/light modes, streaming chat, and voice visualizer dialogs.

---

## 📁 Repository Structure

```
.
├── desktop/                # Tauri v2 + React 19 + TypeScript + Native Rust Core
│   ├── src/
│   │   ├── components/     # ProjectFileDrawer, DiffReviewModal, PromptBar, ChatArea, Sidebar
│   │   └── store/          # Zustand store (activeMode, fileDrawer, projectTree, messages)
│   └── src-tauri/          # Native Rust Engine (SandboxGuard, ProcessRunner, McpClient)
├── frontend/               # Google Gemini Flutter UI Client (Android, iOS, Web, Windows)
│   ├── lib/
│   └── test/
├── docs/                   # Architecture specs and superpowers implementation plans
└── README.md
```

---

## 🚀 Quick Start

### Gemini Desktop with Cowork (Tauri v2 + Rust)

Prerequisites:
- [Node.js](https://nodejs.org/) (v18+)
- [Rust](https://rustup.rs/) (v1.80+)
- [Ollama](https://ollama.com/) running locally: `ollama run qwen2.5-coder:7b`

```bash
cd desktop
npm install
npm run tauri dev
```

### Gemini Flutter Client

Prerequisites:
- [Flutter SDK](https://flutter.dev/) (v3.24+)

```bash
cd frontend
flutter pub get
flutter run
```

---

## 🛡️ Security Model (Desktop Agent)

1. **Tier 1 (Safe Reads)**: `read_file`, `list_directory`, `search_files` execute immediately within the designated project directory.
2. **Tier 2 (File Mutations)**: `write_file`, `apply_diff` calculate unified diffs and prompt for human approval before applying changes to disk.
3. **Tier 3 (Shell Commands)**: `run_command` requires interactive user confirmation with an immediate process termination kill-switch.
