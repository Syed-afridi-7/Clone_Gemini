import React, { useState, useRef, useEffect } from "react";
import { invoke } from "@tauri-apps/api/core";
import { ArrowUp, Square } from "lucide-react";
import { useChatStore } from "../store/chatStore";

interface PromptBarProps {
  onStartTurn: (assistantId: string) => void;
}

export function PromptBar({ onStartTurn }: PromptBarProps) {
  const [text, setText] = useState("");
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const {
    agentRunning,
    workspacePath,
    selectedModel,
    addUserMessage,
    addAssistantMessage,
  } = useChatStore();

  const handleSend = async () => {
    const trimmed = text.trim();
    if (!trimmed || agentRunning) return;

    if (!workspacePath) {
      alert("Please select a workspace folder first using 'Open Folder' above.");
      return;
    }

    if (!selectedModel) {
      alert("Please ensure Ollama is running and a model is selected in the top bar.");
      return;
    }

    setText("");
    if (textareaRef.current) {
      textareaRef.current.style.height = "auto";
    }

    addUserMessage(trimmed);
    const assistantId = addAssistantMessage();
    onStartTurn(assistantId);

    try {
      await invoke("send_agent_prompt", { prompt: trimmed });
    } catch (err) {
      console.error("Failed to send prompt:", err);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      void handleSend();
    }
  };

  // Auto-resize textarea up to 200px
  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = "auto";
      textareaRef.current.style.height = `${Math.min(
        textareaRef.current.scrollHeight,
        200
      )}px`;
    }
  }, [text]);

  return (
    <div
      style={{
        padding: "1rem 2rem 1.5rem",
        backgroundColor: "#131314",
        display: "flex",
        justifyContent: "center",
      }}
    >
      <div
        style={{
          width: "100%",
          maxWidth: "800px",
          backgroundColor: "#1E1F20",
          border: "1px solid #3C4043",
          borderRadius: "24px",
          padding: "12px 18px",
          display: "flex",
          alignItems: "flex-end",
          gap: "12px",
          boxShadow: "0 4px 20px rgba(0,0,0,0.25)",
        }}
      >
        <textarea
          ref={textareaRef}
          value={text}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={
            workspacePath
              ? "Ask Gemini to code, refactor, explain, or run tests..."
              : "Select a workspace folder to begin coding..."
          }
          rows={1}
          style={{
            flex: 1,
            backgroundColor: "transparent",
            border: "none",
            outline: "none",
            color: "#E3E3E3",
            fontFamily: "'Google Sans', sans-serif",
            fontSize: "0.95rem",
            lineHeight: 1.5,
            resize: "none",
            maxHeight: "200px",
          }}
        />

        {/* Send / Stop Action Button */}
        <button
          onClick={handleSend}
          disabled={(!text.trim() && !agentRunning) || !workspacePath}
          style={{
            width: "36px",
            height: "36px",
            borderRadius: "50%",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            border: "none",
            cursor:
              (!text.trim() && !agentRunning) || !workspacePath
                ? "not-allowed"
                : "pointer",
            background: agentRunning
              ? "#D96570"
              : text.trim()
              ? "linear-gradient(135deg, #4285F4, #9B72CB, #D96570)"
              : "#282A2C",
            color: "#FFFFFF",
            flexShrink: 0,
            transition: "all 0.2s",
            opacity: (!text.trim() && !agentRunning) || !workspacePath ? 0.4 : 1,
          }}
          title={agentRunning ? "Agent is working" : "Send message"}
        >
          {agentRunning ? <Square size={16} fill="white" /> : <ArrowUp size={18} />}
        </button>
      </div>
    </div>
  );
}
