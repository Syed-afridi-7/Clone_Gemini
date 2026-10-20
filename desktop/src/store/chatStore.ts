import { create } from "zustand";

export type MessageRole = "user" | "assistant";
export type AppMode = "chat" | "cowork";

export interface FileNode {
  name: string;
  path: string;
  is_dir: boolean;
  children?: FileNode[];
}

export interface ToolEvent {
  id: string;
  toolName: string;
  status: "running" | "success" | "error";
  detail: string;
  timestamp: number;
}

export interface ChatMessage {
  id: string;
  role: MessageRole;
  content: string;
  toolEvents: ToolEvent[];
  isStreaming: boolean;
  timestamp: number;
}

export interface PendingApproval {
  requestId: string;
  type: "diff" | "command";
  filePath?: string;
  originalContent?: string;
  newContent?: string;
  unifiedDiff?: string;
  command?: string;
  cwd?: string;
}

export interface OllamaModel {
  name: string;
  size: number;
  modified_at: string;
}

interface ChatState {
  // Navigation mode: standard general chat vs project cowork
  activeMode: AppMode;
  fileDrawerOpen: boolean;

  // Project file tree (for Cowork mode)
  projectTree: FileNode[];
  treeLoading: boolean;
  selectedFile: string | null;

  // Conversation
  messages: ChatMessage[];

  // Agent state
  agentRunning: boolean;

  // Workspace
  workspacePath: string;

  // Ollama model
  selectedModel: string;
  availableModels: OllamaModel[];
  modelsLoading: boolean;

  // Pending approval (diff or command gate)
  pendingApproval: PendingApproval | null;

  // Actions
  setActiveMode: (mode: AppMode) => void;
  setFileDrawerOpen: (open: boolean) => void;
  toggleFileDrawer: () => void;
  setProjectTree: (tree: FileNode[]) => void;
  setTreeLoading: (loading: boolean) => void;
  setSelectedFile: (file: string | null) => void;
  addUserMessage: (content: string) => string;
  addAssistantMessage: () => string;
  appendToken: (messageId: string, token: string) => void;
  finishStreaming: (messageId: string) => void;
  addToolEvent: (messageId: string, event: ToolEvent) => void;
  updateToolEvent: (messageId: string, eventId: string, updates: Partial<ToolEvent>) => void;
  setAgentRunning: (running: boolean) => void;
  setWorkspacePath: (path: string) => void;
  setSelectedModel: (model: string) => void;
  setAvailableModels: (models: OllamaModel[]) => void;
  setModelsLoading: (loading: boolean) => void;
  setPendingApproval: (approval: PendingApproval | null) => void;
  clearMessages: () => void;
}

let messageIdCounter = 0;
const nextId = () => `msg-${Date.now()}-${++messageIdCounter}`;

export const useChatStore = create<ChatState>((set) => ({
  activeMode: "cowork", // Default to Gemini Cowork
  fileDrawerOpen: true,
  projectTree: [],
  treeLoading: false,
  selectedFile: null,

  messages: [],
  agentRunning: false,
  workspacePath: "",
  selectedModel: "",
  availableModels: [],
  modelsLoading: false,
  pendingApproval: null,

  setActiveMode: (mode) => set({ activeMode: mode }),
  setFileDrawerOpen: (open) => set({ fileDrawerOpen: open }),
  toggleFileDrawer: () => set((state) => ({ fileDrawerOpen: !state.fileDrawerOpen })),
  setProjectTree: (tree) => set({ projectTree: tree }),
  setTreeLoading: (loading) => set({ treeLoading: loading }),
  setSelectedFile: (file) => set({ selectedFile: file }),

  addUserMessage: (content) => {
    const id = nextId();
    set((state) => ({
      messages: [
        ...state.messages,
        {
          id,
          role: "user",
          content,
          toolEvents: [],
          isStreaming: false,
          timestamp: Date.now(),
        },
      ],
    }));
    return id;
  },

  addAssistantMessage: () => {
    const id = nextId();
    set((state) => ({
      messages: [
        ...state.messages,
        {
          id,
          role: "assistant",
          content: "",
          toolEvents: [],
          isStreaming: true,
          timestamp: Date.now(),
        },
      ],
    }));
    return id;
  },

  appendToken: (messageId, token) => {
    set((state) => ({
      messages: state.messages.map((m) =>
        m.id === messageId ? { ...m, content: m.content + token } : m
      ),
    }));
  },

  finishStreaming: (messageId) => {
    set((state) => ({
      messages: state.messages.map((m) =>
        m.id === messageId ? { ...m, isStreaming: false } : m
      ),
    }));
  },

  addToolEvent: (messageId, event) => {
    set((state) => ({
      messages: state.messages.map((m) =>
        m.id === messageId
          ? { ...m, toolEvents: [...m.toolEvents, event] }
          : m
      ),
    }));
  },

  updateToolEvent: (messageId, eventId, updates) => {
    set((state) => ({
      messages: state.messages.map((m) =>
        m.id === messageId
          ? {
              ...m,
              toolEvents: m.toolEvents.map((e) =>
                e.id === eventId ? { ...e, ...updates } : e
              ),
            }
          : m
      ),
    }));
  },

  setAgentRunning: (running) => set({ agentRunning: running }),
  setWorkspacePath: (path) => set({ workspacePath: path }),
  setSelectedModel: (model) => set({ selectedModel: model }),
  setAvailableModels: (models) => set({ availableModels: models }),
  setModelsLoading: (loading) => set({ modelsLoading: loading }),
  setPendingApproval: (approval) => set({ pendingApproval: approval }),
  clearMessages: () => set({ messages: [] }),
}));
