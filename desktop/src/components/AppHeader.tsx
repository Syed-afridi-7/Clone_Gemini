import { useEffect, useRef, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { ChevronDown, Wifi, WifiOff } from "lucide-react";
import { GeminiSparkle } from "./GeminiSparkle";
import { useChatStore } from "../store/chatStore";

interface OllamaTagsResponse {
  models: Array<{
    name: string;
    size: number;
    modified_at: string;
  }>;
}

export function AppHeader() {
  const {
    selectedModel,
    availableModels,
    modelsLoading,
    setSelectedModel,
    setAvailableModels,
    setModelsLoading,
  } = useChatStore();

  const [ollamaOnline, setOllamaOnline] = useState<boolean | null>(null);
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    async function loadModels() {
      setModelsLoading(true);
      try {
        const response = await invoke<OllamaTagsResponse>("list_ollama_models");
        const models = response.models ?? [];
        setAvailableModels(models);
        setOllamaOnline(true);
        if (models.length > 0 && !selectedModel) {
          setSelectedModel(models[0].name);
        }
      } catch {
        setOllamaOnline(false);
        setAvailableModels([]);
      } finally {
        setModelsLoading(false);
      }
    }
    void loadModels();
  }, [selectedModel, setAvailableModels, setModelsLoading, setSelectedModel]);

  // Close dropdown on outside click
  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setDropdownOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const displayModel = selectedModel
    ? selectedModel.split(":")[0]
    : modelsLoading
    ? "Loading..."
    : "No model";

  return (
    <header
      style={{
        backgroundColor: "#1E1F20",
        borderBottom: "1px solid #3C4043",
        padding: "0 1.5rem",
        height: "56px",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        flexShrink: 0,
        gap: "1rem",
      }}
    >
      {/* Logo + Name */}
      <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
        <GeminiSparkle size={28} />
        <span
          style={{
            background: "linear-gradient(90deg, #4285F4, #9B72CB, #D96570)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            fontFamily: "'Google Sans', 'Outfit', sans-serif",
            fontSize: "1.2rem",
            fontWeight: 600,
            letterSpacing: "-0.01em",
          }}
        >
          Gemini Desktop
        </span>
      </div>

      {/* Right side: Ollama status + model selector */}
      <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
        {/* Ollama status badge */}
        <div
          title={ollamaOnline ? "Ollama connected" : "Ollama offline"}
          style={{
            display: "flex",
            alignItems: "center",
            gap: "5px",
            padding: "3px 10px",
            borderRadius: "999px",
            backgroundColor: ollamaOnline === true ? "rgba(52, 199, 89, 0.12)" : "rgba(217, 101, 112, 0.12)",
            border: `1px solid ${ollamaOnline === true ? "rgba(52, 199, 89, 0.3)" : "rgba(217, 101, 112, 0.3)"}`,
            fontSize: "0.75rem",
            color: ollamaOnline === true ? "#34c759" : "#D96570",
          }}
        >
          {ollamaOnline === true ? (
            <Wifi size={12} />
          ) : (
            <WifiOff size={12} />
          )}
          <span>{ollamaOnline === true ? "Ollama" : "Offline"}</span>
        </div>

        {/* Model selector */}
        <div ref={dropdownRef} style={{ position: "relative" }}>
          <button
            onClick={() => setDropdownOpen((o) => !o)}
            disabled={modelsLoading || availableModels.length === 0}
            style={{
              display: "flex",
              alignItems: "center",
              gap: "6px",
              padding: "5px 12px",
              borderRadius: "8px",
              backgroundColor: dropdownOpen ? "#282A2C" : "transparent",
              border: "1px solid #3C4043",
              color: "#E3E3E3",
              cursor: modelsLoading ? "not-allowed" : "pointer",
              fontSize: "0.85rem",
              fontFamily: "'Google Sans', sans-serif",
              transition: "background-color 0.15s",
            }}
          >
            <span>{displayModel}</span>
            <ChevronDown size={14} style={{ opacity: 0.7, transform: dropdownOpen ? "rotate(180deg)" : "rotate(0deg)", transition: "transform 0.2s" }} />
          </button>

          {dropdownOpen && availableModels.length > 0 && (
            <div
              style={{
                position: "absolute",
                top: "calc(100% + 6px)",
                right: 0,
                minWidth: "220px",
                backgroundColor: "#1E1F20",
                border: "1px solid #3C4043",
                borderRadius: "12px",
                padding: "6px",
                zIndex: 100,
                boxShadow: "0 8px 32px rgba(0,0,0,0.5)",
              }}
            >
              {availableModels.map((model) => (
                <button
                  key={model.name}
                  onClick={() => {
                    setSelectedModel(model.name);
                    setDropdownOpen(false);
                  }}
                  style={{
                    display: "block",
                    width: "100%",
                    textAlign: "left",
                    padding: "8px 12px",
                    borderRadius: "8px",
                    backgroundColor: model.name === selectedModel ? "#282A2C" : "transparent",
                    border: "none",
                    color: "#E3E3E3",
                    cursor: "pointer",
                    fontSize: "0.85rem",
                    fontFamily: "'Google Sans', sans-serif",
                  }}
                  onMouseEnter={(e) => {
                    (e.currentTarget as HTMLButtonElement).style.backgroundColor = "#282A2C";
                  }}
                  onMouseLeave={(e) => {
                    (e.currentTarget as HTMLButtonElement).style.backgroundColor =
                      model.name === selectedModel ? "#282A2C" : "transparent";
                  }}
                >
                  <div style={{ fontWeight: 500 }}>{model.name.split(":")[0]}</div>
                  {model.name.includes(":") && (
                    <div style={{ fontSize: "0.73rem", color: "#9AA0A6", marginTop: "2px" }}>
                      {model.name.split(":")[1]}
                    </div>
                  )}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
