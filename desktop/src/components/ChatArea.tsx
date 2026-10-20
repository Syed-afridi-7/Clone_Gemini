import { useEffect, useRef } from "react";
import { MessageBubble } from "./MessageBubble";
import { PromptBar } from "./PromptBar";
import { useChatStore } from "../store/chatStore";
import { useAgentEvents } from "../hooks/useAgentEvents";
import { isTauriEnvironment } from "../utils/tauri";
import { Code2, Sparkles, Terminal } from "lucide-react";

export function ChatArea() {
  const { messages, workspacePath, addUserMessage, addAssistantMessage } = useChatStore();
  const { startAgentTurn } = useAgentEvents();
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages]);

  const handleSuggestion = (prompt: string) => {
    if (!workspacePath) {
      alert("Please select a workspace folder first!");
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
            <div style={{ textAlign: "center" }}>
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
                What can I build, refactor, or test for you today?
              </p>
            </div>

            {/* Starter Suggestion Chips */}
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
                gap: "12px",
                width: "100%",
                maxWidth: "700px",
                marginTop: "16px",
              }}
            >
              {[
                {
                  icon: <Code2 size={16} className="text-blue-400" />,
                  title: "Inspect workspace",
                  prompt: "List all files in this project and give me a brief overview of the project structure.",
                },
                {
                  icon: <Sparkles size={16} className="text-purple-400" />,
                  title: "Find & fix bugs",
                  prompt: "Search the codebase for TODOs or obvious syntax bugs and suggest improvements.",
                },
                {
                  icon: <Terminal size={16} className="text-amber-400" />,
                  title: "Run project tests",
                  prompt: "Check what test framework this project uses and run its unit tests.",
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
