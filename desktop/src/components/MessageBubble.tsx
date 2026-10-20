import ReactMarkdown from "react-markdown";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { vscDarkPlus } from "react-syntax-highlighter/dist/esm/styles/prism";
import { GeminiSparkle } from "./GeminiSparkle";
import { ToolEventCard } from "./ToolEventCard";
import { ChatMessage } from "../store/chatStore";

interface MessageBubbleProps {
  message: ChatMessage;
}

export function MessageBubble({ message }: MessageBubbleProps) {
  const isUser = message.role === "user";

  if (isUser) {
    return (
      <div
        style={{
          display: "flex",
          justifyContent: "flex-end",
          marginBottom: "1.5rem",
          paddingLeft: "2rem",
        }}
      >
        <div
          style={{
            maxWidth: "75%",
            backgroundColor: "#282A2C",
            color: "#E3E3E3",
            padding: "12px 18px",
            borderRadius: "20px 20px 4px 20px",
            fontSize: "0.93rem",
            lineHeight: 1.5,
            whiteSpace: "pre-wrap",
            wordBreak: "break-word",
            fontFamily: "'Google Sans', sans-serif",
          }}
        >
          {message.content}
        </div>
      </div>
    );
  }

  return (
    <div
      style={{
        display: "flex",
        gap: "14px",
        marginBottom: "2rem",
        alignItems: "flex-start",
      }}
    >
      {/* Gemini Sparkle Avatar */}
      <div style={{ flexShrink: 0, marginTop: "4px" }}>
        <GeminiSparkle size={26} />
      </div>

      {/* Message content container */}
      <div style={{ flex: 1, minWidth: 0, overflow: "hidden" }}>
        {/* Tool event chips if any */}
        {message.toolEvents.length > 0 && (
          <div
            style={{
              display: "flex",
              flexWrap: "wrap",
              marginBottom: "10px",
            }}
          >
            {message.toolEvents.map((evt) => (
              <ToolEventCard key={evt.id} event={evt} />
            ))}
          </div>
        )}

        {/* Streamed text / Markdown */}
        <div
          className="prose prose-invert max-w-none"
          style={{
            color: "#E3E3E3",
            fontSize: "0.95rem",
            lineHeight: 1.6,
            fontFamily: "'Google Sans', 'Roboto', sans-serif",
          }}
        >
          <ReactMarkdown
            components={{
              code({ className, children, ...props }) {
                const match = /language-(\w+)/.exec(className || "");
                const isInline = !match && !String(children).includes("\n");

                return isInline ? (
                  <code
                    style={{
                      backgroundColor: "#282A2C",
                      padding: "2px 6px",
                      borderRadius: "4px",
                      fontFamily: "monospace",
                      fontSize: "0.85em",
                      color: "#9B72CB",
                    }}
                    {...props}
                  >
                    {children}
                  </code>
                ) : (
                  <div
                    style={{
                      borderRadius: "8px",
                      overflow: "hidden",
                      margin: "12px 0",
                      border: "1px solid #3C4043",
                    }}
                  >
                    <SyntaxHighlighter
                      style={vscDarkPlus}
                      language={match ? match[1] : "text"}
                      PreTag="div"
                      customStyle={{
                        margin: 0,
                        padding: "14px",
                        backgroundColor: "#1E1F20",
                        fontSize: "0.85rem",
                      }}
                    >
                      {String(children).replace(/\n$/, "")}
                    </SyntaxHighlighter>
                  </div>
                );
              },
            }}
          >
            {message.content}
          </ReactMarkdown>

          {/* Streaming cursor indicator */}
          {message.isStreaming && (
            <span
              style={{
                display: "inline-block",
                width: "8px",
                height: "15px",
                marginLeft: "4px",
                backgroundColor: "#4285F4",
                verticalAlign: "middle",
                animation: "pulse 1s infinite",
              }}
            />
          )}
        </div>
      </div>
    </div>
  );
}
