import { useEffect, useRef } from "react";
import { MessageBubble } from "./MessageBubble";
import { PromptBar } from "./PromptBar";
import { useChatStore } from "../store/chatStore";
import { useAgentEvents } from "../hooks/useAgentEvents";
import { isTauriEnvironment } from "../utils/tauri";
import { Code2, Sparkles, Terminal, FileSearch, Zap, Bot } from "lucide-react";

export function ChatArea() {
  const { messages, workspacePath, activeMode, addUserMessage, addAssistantMessage } =
    useChatStore();
  const { startAgentTurn } = useAgentEvents();
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages]);

  const handleSuggestion = (prompt: string) => {
    if (activeMode === "cowork" && !workspacePath) {
      alert("Please select a workspace folder first using 'Open Project' in the file drawer!");
      return;
    }
    addUserMessage(prompt);
    const assistantId = addAssistantMessage();
    startAgentTurn(assistantId);

    if (isTauriEnvironment()) {
      import("@tauri-apps/api/core").then(({ invoke }) => {
        void invoke("send_agent_prompt", { prompt });
      });
    } else {
      alert(
        "Running in Web Browser preview mode. To execute local file edits and shell commands with the Rust engine, launch the desktop app with: npm run tauri dev"
      );
    }
  };

  const folderName = workspacePath
    ? workspacePath.replace(/\\/g, "/").split("/").filter(Boolean).pop()
    : null;

  return (
    <div
      style={{
        flex: 1,
        display: "flex",
        flexDirection: "column",
        height: "100%",
        overflow: "hidden",
        backgroundColor: "#131314",
      }}
    >
      {/* Scrollable messages container */}
      <div
        ref={scrollRef}
        style={{
          flex: 1,
          overflowY: "auto",
          padding: "2rem 2.5rem",
        }}
      >
        {messages.length === 0 ? (
          <div
            style={{
              height: "100%",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              gap: "24px",
              paddingBottom: "4rem",
            }}
          >
            {activeMode === "cowork" ? (
              // Gemini Cowork Hero Screen
              <div style={{ textAlign: "center", maxWidth: "680px" }}>
                <div
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "6px",
                    padding: "4px 12px",
                    borderRadius: "999px",
                    backgroundColor: "rgba(155, 114, 203, 0.12)",
                    border: "1px solid rgba(155, 114, 203, 0.3)",
                    color: "#9B72CB",
                    fontSize: "0.78rem",
                    fontWeight: 600,
                    marginBottom: "12px",
                    letterSpacing: "0.02em",
                  }}
                >
                  <Zap size={13} style={{ color: "#D96570" }} />
                  <span>GEMINI COWORK — LOCAL WORKSPACE CONTROL</span>
                </div>

                <h1
                  style={{
                    fontSize: "2.8rem",
                    fontWeight: 500,
                    background: "linear-gradient(135deg, #4285F4 0%, #9B72CB 50%, #D96570 100%)",
                    WebkitBackgroundClip: "text",
                    WebkitTextFillColor: "transparent",
                    fontFamily: "'Google Sans', sans-serif",
                    letterSpacing: "-0.02em",
                    marginBottom: "8px",
                  }}
                >
                  {folderName ? `Project: ${folderName}` : "Gemini Cowork"}
                </h1>
                <p style={{ color: "#9AA0A6", fontSize: "1rem", lineHeight: 1.5 }}>
                  {folderName
                    ? "Grounded in your local repository. Ask Gemini to inspect architecture, refactor code, apply diffs, and run terminal checks."
                    : "Open a local project folder to start grounded agentic coding with interactive diffs."}
                </p>
              </div>
            ) : (
              // Standard Gemini Chat Hero Screen
              <div style={{ textAlign: "center" }}>
                <div
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "6px",
                    padding: "4px 12px",
                    borderRadius: "999px",
                    backgroundColor: "rgba(66, 133, 244, 0.12)",
                    border: "1px solid rgba(66, 133, 244, 0.3)",
                    color: "#4285F4",
                    fontSize: "0.78rem",
                    fontWeight: 600,
                    marginBottom: "12px",
                  }}
                >
                  <Bot size={13} />
                  <span>GEMINI GENERAL CHAT</span>
                </div>

                <h1
                  style={{
                    fontSize: "3.2rem",
                    fontWeight: 500,
                    background: "linear-gradient(135deg, #4285F4 0%, #9B72CB 50%, #D96570 100%)",
                    WebkitBackgroundClip: "text",
                    WebkitTextFillColor: "transparent",
                    fontFamily: "'Google Sans', sans-serif",
                    letterSpacing: "-0.02em",
                    marginBottom: "8px",
                  }}
                >
                  Hello, Human.
                </h1>
                <p style={{ color: "#9AA0A6", fontSize: "1.1rem" }}>
                  What can I help you explore, draft, or answer today?
                </p>
              </div>
            )}

            {/* Quick Action Chips */}
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
                gap: "12px",
                width: "100%",
                maxWidth: "700px",
                marginTop: "12px",
              }}
            >
              {activeMode === "cowork"
                ? [
                    {
                      icon: <Code2 size={16} className="text-blue-400" />,
                      title: "Inspect architecture",
                      prompt: "Inspect the file structure of this workspace and summarize its architecture and key modules.",
                    },
                    {
                      icon: <Terminal size={16} className="text-amber-400" />,
                      title: "Run project tests",
                      prompt: "Detect this project's test framework and run its test suite, explaining any failures.",
                    },
                    {
                      icon: <FileSearch size={16} className="text-purple-400" />,
                      title: "Find TODOs & bugs",
                      prompt: "Search the codebase for TODOs, fixme comments, or potential logic bugs and propose fixes.",
                    },
                  ].map((card, idx) => (
                    <button
                      key={idx}
                      onClick={() => handleSuggestion(card.prompt)}
                      style={{
                        backgroundColor: "#1E1F20",
                        border: "1px solid #3C4043",
                        borderRadius: "14px",
                        padding: "16px",
                        textAlign: "left",
                        cursor: "pointer",
                        display: "flex",
                        flexDirection: "column",
                        gap: "8px",
                        transition: "all 0.2s",
                      }}
                      onMouseEnter={(e) => {
                        (e.currentTarget as HTMLButtonElement).style.backgroundColor = "#282A2C";
                        (e.currentTarget as HTMLButtonElement).style.borderColor = "#9B72CB";
                      }}
                      onMouseLeave={(e) => {
                        (e.currentTarget as HTMLButtonElement).style.backgroundColor = "#1E1F20";
                        (e.currentTarget as HTMLButtonElement).style.borderColor = "#3C4043";
                      }}
                    >
                      <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                        {card.icon}
                        <span style={{ color: "#E3E3E3", fontWeight: 500, fontSize: "0.9rem" }}>
                          {card.title}
                        </span>
                      </div>
                      <span style={{ color: "#9AA0A6", fontSize: "0.78rem", lineHeight: 1.4 }}>
                        {card.prompt}
                      </span>
                    </button>
                  ))
                : [
                    {
                      icon: <Sparkles size={16} className="text-purple-400" />,
                      title: "Brainstorm ideas",
                      prompt: "Give me 5 creative ideas to build using Google Gemini and local AI agents.",
                    },
                    {
                      icon: <Code2 size={16} className="text-blue-400" />,
                      title: "Write an algorithm",
                      prompt: "Write a high-performance LRU cache implementation with time-based eviction.",
                    },
                    {
                      icon: <Terminal size={16} className="text-emerald-400" />,
                      title: "Explain a concept",
                      prompt: "Explain how large language models handle tool calling and JSON function execution.",
                    },
                  ].map((card, idx) => (
                    <button
                      key={idx}
                      onClick={() => handleSuggestion(card.prompt)}
                      style={{
                        backgroundColor: "#1E1F20",
                        border: "1px solid #3C4043",
                        borderRadius: "14px",
                        padding: "16px",
                        textAlign: "left",
                        cursor: "pointer",
                        display: "flex",
                        flexDirection: "column",
                        gap: "8px",
                        transition: "all 0.2s",
                      }}
                      onMouseEnter={(e) => {
                        (e.currentTarget as HTMLButtonElement).style.backgroundColor = "#282A2C";
                        (e.currentTarget as HTMLButtonElement).style.borderColor = "#4285F4";
                      }}
                      onMouseLeave={(e) => {
                        (e.currentTarget as HTMLButtonElement).style.backgroundColor = "#1E1F20";
                        (e.currentTarget as HTMLButtonElement).style.borderColor = "#3C4043";
                      }}
                    >
                      <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                        {card.icon}
                        <span style={{ color: "#E3E3E3", fontWeight: 500, fontSize: "0.9rem" }}>
                          {card.title}
                        </span>
                      </div>
                      <span style={{ color: "#9AA0A6", fontSize: "0.78rem", lineHeight: 1.4 }}>
                        {card.prompt}
                      </span>
                    </button>
                  ))}
            </div>
          </div>
        ) : (
          <div style={{ maxWidth: "840px", margin: "0 auto", width: "100%" }}>
            {messages.map((msg) => (
              <MessageBubble key={msg.id} message={msg} />
            ))}
          </div>
        )}
      </div>

      {/* Fixed bottom PromptBar */}
      <PromptBar onStartTurn={startAgentTurn} />
    </div>
  );
}
