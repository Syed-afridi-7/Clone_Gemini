import {
  MessageSquare,
  Plus,
  Settings,
  Trash2,
  Zap,
  FolderTree,
  Folder,
} from "lucide-react";
import { GeminiSparkle } from "./GeminiSparkle";
import { useChatStore } from "../store/chatStore";

export function Sidebar() {
  const {
    activeMode,
    setActiveMode,
    clearMessages,
    workspacePath,
    fileDrawerOpen,
    toggleFileDrawer,
  } = useChatStore();

  const folderName = workspacePath
    ? workspacePath.replace(/\\/g, "/").split("/").filter(Boolean).pop()
    : null;

  return (
    <aside
      style={{
        width: "250px",
        backgroundColor: "#1E1F20",
        borderRight: "1px solid #3C4043",
        display: "flex",
        flexDirection: "column",
        flexShrink: 0,
        height: "100%",
        overflow: "hidden",
      }}
    >
      {/* Sidebar header */}
      <div
        style={{
          padding: "1rem",
          display: "flex",
          alignItems: "center",
          gap: "10px",
          borderBottom: "1px solid #3C4043",
        }}
      >
        <GeminiSparkle size={22} />
        <span
          style={{
            fontSize: "0.95rem",
            fontWeight: 600,
            fontFamily: "'Google Sans', sans-serif",
            background: "linear-gradient(90deg, #4285F4, #9B72CB)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          Gemini
        </span>
      </div>

      {/* Mode Switcher: Chat vs Gemini Cowork */}
      <div
        style={{
          padding: "0.75rem 0.75rem 0.25rem",
          display: "flex",
          gap: "6px",
          backgroundColor: "#191A1B",
          borderBottom: "1px solid #282A2C",
        }}
      >
        <button
          onClick={() => setActiveMode("chat")}
          style={{
            flex: 1,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: "6px",
            padding: "8px 6px",
            borderRadius: "8px",
            border: activeMode === "chat" ? "1px solid #4285F4" : "1px solid transparent",
            backgroundColor: activeMode === "chat" ? "#282A2C" : "transparent",
            color: activeMode === "chat" ? "#FFFFFF" : "#9AA0A6",
            cursor: "pointer",
            fontSize: "0.8rem",
            fontWeight: activeMode === "chat" ? 600 : 400,
            fontFamily: "'Google Sans', sans-serif",
            transition: "all 0.15s",
          }}
        >
          <MessageSquare size={13} style={{ color: activeMode === "chat" ? "#4285F4" : "#9AA0A6" }} />
          <span>Chat</span>
        </button>

        <button
          onClick={() => setActiveMode("cowork")}
          style={{
            flex: 1,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: "6px",
            padding: "8px 6px",
            borderRadius: "8px",
            border: activeMode === "cowork" ? "1px solid #9B72CB" : "1px solid transparent",
            backgroundColor: activeMode === "cowork" ? "#282A2C" : "transparent",
            color: activeMode === "cowork" ? "#FFFFFF" : "#9AA0A6",
            cursor: "pointer",
            fontSize: "0.8rem",
            fontWeight: activeMode === "cowork" ? 600 : 400,
            fontFamily: "'Google Sans', sans-serif",
            transition: "all 0.15s",
          }}
        >
          <Zap size={13} style={{ color: activeMode === "cowork" ? "#D96570" : "#9AA0A6" }} />
          <span>Cowork</span>
        </button>
      </div>

      {/* New chat button */}
      <div style={{ padding: "0.75rem" }}>
        <button
          onClick={clearMessages}
          style={{
            display: "flex",
            alignItems: "center",
            gap: "8px",
            width: "100%",
            padding: "10px 14px",
            borderRadius: "10px",
            backgroundColor: "transparent",
            border: "1px solid #3C4043",
            color: "#E3E3E3",
            cursor: "pointer",
            fontSize: "0.85rem",
            fontFamily: "'Google Sans', sans-serif",
            transition: "background-color 0.15s",
          }}
          onMouseEnter={(e) =>
            ((e.currentTarget as HTMLButtonElement).style.backgroundColor = "#282A2C")
          }
          onMouseLeave={(e) =>
            ((e.currentTarget as HTMLButtonElement).style.backgroundColor = "transparent")
          }
        >
          <Plus size={15} />
          {activeMode === "cowork" ? "New Cowork Task" : "New conversation"}
        </button>
      </div>

      {/* Cowork Status Badge if in Cowork mode */}
      {activeMode === "cowork" && (
        <div style={{ padding: "0 0.75rem 0.5rem" }}>
          <div
            onClick={toggleFileDrawer}
            style={{
              padding: "8px 12px",
              borderRadius: "8px",
              backgroundColor: "rgba(155, 114, 203, 0.1)",
              border: "1px solid rgba(155, 114, 203, 0.3)",
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              cursor: "pointer",
            }}
            title="Click to toggle project file drawer"
          >
            <div style={{ display: "flex", alignItems: "center", gap: "6px", overflow: "hidden" }}>
              <Folder size={13} style={{ color: "#9B72CB", flexShrink: 0 }} />
              <span
                style={{
                  fontSize: "0.75rem",
                  color: "#E3E3E3",
                  fontWeight: 500,
                  overflow: "hidden",
                  textOverflow: "ellipsis",
                  whiteSpace: "nowrap",
                }}
              >
                {folderName || "No workspace"}
              </span>
            </div>
            <FolderTree
              size={13}
              style={{
                color: fileDrawerOpen ? "#9B72CB" : "#9AA0A6",
                flexShrink: 0,
              }}
            />
          </div>
        </div>
      )}

      {/* Recent label */}
      <div
        style={{
          padding: "0.5rem 1rem 0.25rem",
          fontSize: "0.7rem",
          fontWeight: 600,
          color: "#9AA0A6",
          textTransform: "uppercase",
          letterSpacing: "0.08em",
        }}
      >
        Recent
      </div>

      {/* Placeholder conversation items */}
      <div style={{ flex: 1, overflowY: "auto", padding: "0.25rem 0.75rem" }}>
        {[
          "Refactor auth module",
          "Debug test failures",
          "Add dark mode toggle",
        ].map((label, i) => (
          <button
            key={i}
            style={{
              display: "flex",
              alignItems: "center",
              gap: "8px",
              width: "100%",
              padding: "9px 12px",
              borderRadius: "8px",
              backgroundColor: "transparent",
              border: "none",
              color: "#9AA0A6",
              cursor: "pointer",
              fontSize: "0.82rem",
              fontFamily: "'Google Sans', sans-serif",
              textAlign: "left",
              transition: "all 0.15s",
            }}
            onMouseEnter={(e) => {
              (e.currentTarget as HTMLButtonElement).style.backgroundColor = "#282A2C";
              (e.currentTarget as HTMLButtonElement).style.color = "#E3E3E3";
            }}
            onMouseLeave={(e) => {
              (e.currentTarget as HTMLButtonElement).style.backgroundColor = "transparent";
              (e.currentTarget as HTMLButtonElement).style.color = "#9AA0A6";
            }}
          >
            <MessageSquare size={14} style={{ flexShrink: 0 }} />
            <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
              {label}
            </span>
          </button>
        ))}
      </div>

      {/* Bottom actions */}
      <div
        style={{
          padding: "0.75rem",
          borderTop: "1px solid #3C4043",
          display: "flex",
          flexDirection: "column",
          gap: "4px",
        }}
      >
        <button
          style={{
            display: "flex",
            alignItems: "center",
            gap: "8px",
            width: "100%",
            padding: "9px 12px",
            borderRadius: "8px",
            backgroundColor: "transparent",
            border: "none",
            color: "#9AA0A6",
            cursor: "pointer",
            fontSize: "0.82rem",
            fontFamily: "'Google Sans', sans-serif",
            textAlign: "left",
          }}
          onMouseEnter={(e) => {
            (e.currentTarget as HTMLButtonElement).style.backgroundColor = "#282A2C";
            (e.currentTarget as HTMLButtonElement).style.color = "#E3E3E3";
          }}
          onMouseLeave={(e) => {
            (e.currentTarget as HTMLButtonElement).style.backgroundColor = "transparent";
            (e.currentTarget as HTMLButtonElement).style.color = "#9AA0A6";
          }}
        >
          <Settings size={15} />
          Settings
        </button>
        <button
          onClick={clearMessages}
          style={{
            display: "flex",
            alignItems: "center",
            gap: "8px",
            width: "100%",
            padding: "9px 12px",
            borderRadius: "8px",
            backgroundColor: "transparent",
            border: "none",
            color: "#9AA0A6",
            cursor: "pointer",
            fontSize: "0.82rem",
            fontFamily: "'Google Sans', sans-serif",
            textAlign: "left",
          }}
          onMouseEnter={(e) => {
            (e.currentTarget as HTMLButtonElement).style.backgroundColor = "rgba(217,101,112,0.1)";
            (e.currentTarget as HTMLButtonElement).style.color = "#D96570";
          }}
          onMouseLeave={(e) => {
            (e.currentTarget as HTMLButtonElement).style.backgroundColor = "transparent";
            (e.currentTarget as HTMLButtonElement).style.color = "#9AA0A6";
          }}
        >
          <Trash2 size={15} />
          Clear history
        </button>
      </div>
    </aside>
  );
}
