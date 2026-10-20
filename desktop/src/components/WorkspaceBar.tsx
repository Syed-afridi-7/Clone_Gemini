import { useState } from "react";
import { FolderOpen, Folder, ChevronRight } from "lucide-react";
import { useChatStore } from "../store/chatStore";
import { isTauriEnvironment } from "../utils/tauri";

export function WorkspaceBar() {
  const { workspacePath, setWorkspacePath } = useChatStore();
  const [isPickerOpen, setIsPickerOpen] = useState(false);

  const handlePickFolder = async () => {
    if (isPickerOpen) return;
    setIsPickerOpen(true);
    try {
      if (isTauriEnvironment()) {
        const { open } = await import("@tauri-apps/plugin-dialog");
        const { invoke } = await import("@tauri-apps/api/core");
        const selected = await open({
          directory: true,
          multiple: false,
          title: "Select Workspace Folder",
        });
        if (typeof selected === "string" && selected.trim()) {
          setWorkspacePath(selected);
          await invoke("set_workspace", { path: selected });
        }
      } else {
        // Fallback for testing in standard web browser
        const entered = prompt(
          "Enter your local project workspace directory path (e.g. E:\\gemini-clone):",
          workspacePath || "E:\\gemini-clone"
        );
        if (entered && entered.trim()) {
          setWorkspacePath(entered.trim());
        }
      }
    } catch (err) {
      console.error("Folder picker error:", err);
    } finally {
      setIsPickerOpen(false);
    }
  };

  const displayPath = workspacePath
    ? workspacePath.replace(/\\/g, "/").split("/").slice(-2).join("/")
    : null;

  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: "8px",
        padding: "6px 16px",
        backgroundColor: "#1E1F20",
        borderBottom: "1px solid #3C4043",
        flexShrink: 0,
      }}
    >
      <button
        onClick={handlePickFolder}
        disabled={isPickerOpen}
        style={{
          display: "flex",
          alignItems: "center",
          gap: "6px",
          padding: "4px 10px",
          borderRadius: "6px",
          backgroundColor: "transparent",
          border: "1px solid #3C4043",
          color: "#9AA0A6",
          cursor: isPickerOpen ? "not-allowed" : "pointer",
          fontSize: "0.78rem",
          fontFamily: "'Google Sans', sans-serif",
          transition: "all 0.15s",
          flexShrink: 0,
        }}
        onMouseEnter={(e) => {
          if (!isPickerOpen) {
            (e.currentTarget as HTMLButtonElement).style.backgroundColor = "#282A2C";
            (e.currentTarget as HTMLButtonElement).style.color = "#E3E3E3";
          }
        }}
        onMouseLeave={(e) => {
          (e.currentTarget as HTMLButtonElement).style.backgroundColor = "transparent";
          (e.currentTarget as HTMLButtonElement).style.color = "#9AA0A6";
        }}
      >
        <FolderOpen size={13} />
        <span>Open Folder</span>
      </button>

      {workspacePath ? (
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "4px",
            fontSize: "0.78rem",
            color: "#9AA0A6",
            overflow: "hidden",
            flex: 1,
          }}
        >
          <Folder size={12} style={{ flexShrink: 0, color: "#4285F4" }} />
          <ChevronRight size={12} style={{ flexShrink: 0, opacity: 0.5 }} />
          <span
            title={workspacePath}
            style={{
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
              color: "#E3E3E3",
              fontFamily: "monospace",
              fontSize: "0.75rem",
            }}
          >
            {displayPath}
          </span>
        </div>
      ) : (
        <span style={{ fontSize: "0.78rem", color: "#9AA0A6", fontStyle: "italic" }}>
          No workspace selected
        </span>
      )}
    </div>
  );
}
