import { useEffect } from "react";
import { Check, X, FileCode, Terminal, AlertTriangle } from "lucide-react";
import { useChatStore } from "../store/chatStore";
import { isTauriEnvironment } from "../utils/tauri";
import * as Diff2Html from "diff2html";
import "diff2html/bundles/css/diff2html.min.css";

export function DiffReviewModal() {
  const { pendingApproval, setPendingApproval } = useChatStore();

  const handleDecision = async (approved: boolean) => {
    if (!pendingApproval) return;
    try {
      if (isTauriEnvironment()) {
        const { invoke } = await import("@tauri-apps/api/core");
        await invoke("approve_permission", {
          requestId: pendingApproval.requestId,
          approved,
        });
      }
    } catch (err) {
      console.error("Failed to submit approval decision:", err);
    } finally {
      setPendingApproval(null);
    }
  };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!pendingApproval) return;
      if (e.key === "Escape") {
        void handleDecision(false);
      } else if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) {
        void handleDecision(true);
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [pendingApproval]);

  if (!pendingApproval) return null;

  const isDiff = pendingApproval.type === "diff";

  // Generate diff2html output if it's a file diff
  let diffHtml = "";
  if (isDiff && pendingApproval.unifiedDiff) {
    try {
      diffHtml = Diff2Html.html(pendingApproval.unifiedDiff, {
        drawFileList: false,
        matching: "lines",
        outputFormat: "line-by-line",
      });
    } catch {
      diffHtml = `<pre class="p-4 text-xs font-mono">${pendingApproval.unifiedDiff}</pre>`;
    }
  }

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        backgroundColor: "rgba(0, 0, 0, 0.75)",
        backdropFilter: "blur(6px)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 9999,
        padding: "2rem",
      }}
    >
      <div
        style={{
          width: "100%",
          maxWidth: "850px",
          maxHeight: "85vh",
          backgroundColor: "#1E1F20",
          border: "1px solid #3C4043",
          borderRadius: "16px",
          display: "flex",
          flexDirection: "column",
          boxShadow: "0 24px 48px rgba(0,0,0,0.6)",
          overflow: "hidden",
        }}
      >
        {/* Modal Header */}
        <div
          style={{
            padding: "1rem 1.5rem",
            borderBottom: "1px solid #3C4043",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            {isDiff ? (
              <FileCode size={20} className="text-purple-400" />
            ) : (
              <Terminal size={20} className="text-amber-400" />
            )}
            <span
              style={{
                color: "#E3E3E3",
                fontWeight: 600,
                fontSize: "1.05rem",
                fontFamily: "'Google Sans', sans-serif",
              }}
            >
              {isDiff ? "Review Proposed Code Changes" : "Confirm Shell Command"}
            </span>
          </div>

          <div
            style={{
              fontSize: "0.78rem",
              color: "#9AA0A6",
              backgroundColor: "#282A2C",
              padding: "4px 8px",
              borderRadius: "6px",
              fontFamily: "monospace",
            }}
          >
            {isDiff ? pendingApproval.filePath : pendingApproval.cwd}
          </div>
        </div>

        {/* Modal Body */}
        <div
          style={{
            flex: 1,
            overflowY: "auto",
            padding: "1.5rem",
            backgroundColor: "#131314",
          }}
        >
          {isDiff ? (
            <div
              className="diff2html-dark-wrapper"
              dangerouslySetInnerHTML={{ __html: diffHtml }}
              style={{
                color: "#E3E3E3",
                fontSize: "0.82rem",
                fontFamily: "monospace",
              }}
            />
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "10px",
                  padding: "12px 16px",
                  borderRadius: "8px",
                  backgroundColor: "rgba(217, 101, 112, 0.12)",
                  border: "1px solid rgba(217, 101, 112, 0.3)",
                  color: "#D96570",
                  fontSize: "0.85rem",
                }}
              >
                <AlertTriangle size={18} style={{ flexShrink: 0 }} />
                <span>
                  The agent wants to execute this command in your project workspace. Confirm to allow.
                </span>
              </div>

              <div
                style={{
                  backgroundColor: "#1E1F20",
                  border: "1px solid #3C4043",
                  borderRadius: "8px",
                  padding: "16px",
                }}
              >
                <div style={{ fontSize: "0.75rem", color: "#9AA0A6", marginBottom: "6px" }}>
                  COMMAND:
                </div>
                <pre
                  style={{
                    color: "#34C759",
                    fontFamily: "monospace",
                    fontSize: "0.95rem",
                    margin: 0,
                    whiteSpace: "pre-wrap",
                    wordBreak: "break-all",
                  }}
                >
                  {pendingApproval.command}
                </pre>
              </div>
            </div>
          )}
        </div>

        {/* Modal Actions Footer */}
        <div
          style={{
            padding: "1rem 1.5rem",
            borderTop: "1px solid #3C4043",
            backgroundColor: "#1E1F20",
            display: "flex",
            alignItems: "center",
            justifyContent: "flex-end",
            gap: "12px",
          }}
        >
          <button
            onClick={() => handleDecision(false)}
            style={{
              display: "flex",
              alignItems: "center",
              gap: "6px",
              padding: "8px 16px",
              borderRadius: "8px",
              backgroundColor: "transparent",
              border: "1px solid #3C4043",
              color: "#9AA0A6",
              cursor: "pointer",
              fontSize: "0.85rem",
              fontFamily: "'Google Sans', sans-serif",
            }}
          >
            <X size={15} />
            <span>Reject (Esc)</span>
          </button>

          <button
            onClick={() => handleDecision(true)}
            style={{
              display: "flex",
              alignItems: "center",
              gap: "6px",
              padding: "8px 18px",
              borderRadius: "8px",
              border: "none",
              background: "linear-gradient(135deg, #4285F4, #9B72CB, #D96570)",
              color: "#FFFFFF",
              fontWeight: 500,
              cursor: "pointer",
              fontSize: "0.85rem",
              fontFamily: "'Google Sans', sans-serif",
              boxShadow: "0 2px 10px rgba(66, 133, 244, 0.3)",
            }}
          >
            <Check size={15} />
            <span>Approve & Continue (Ctrl+Enter)</span>
          </button>
        </div>
      </div>
    </div>
  );
}
