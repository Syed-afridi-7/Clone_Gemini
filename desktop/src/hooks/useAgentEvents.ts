import { useEffect, useRef } from "react";
import { listen } from "@tauri-apps/api/event";
import { useChatStore, ToolEvent, PendingApproval } from "../store/chatStore";
import { isTauriEnvironment } from "../utils/tauri";

interface TokenPayload {
  token: string;
}

interface ToolStartedPayload {
  tool_name: string;
  detail: string;
}

interface StdoutPayload {
  text: string;
}

interface DiffReadyPayload {
  request_id: string;
  file_path: string;
  original_content: string;
  new_content: string;
  unified_diff: string;
}

interface CommandApprovalPayload {
  request_id: string;
  command: string;
  cwd: string;
}

interface ErrorPayload {
  error: string;
}

export function useAgentEvents() {
  const {
    appendToken,
    finishStreaming,
    addToolEvent,
    updateToolEvent,
    setAgentRunning,
    setPendingApproval,
  } = useChatStore();

  const activeMsgIdRef = useRef<string | null>(null);
  const activeToolIdRef = useRef<string | null>(null);

  const startAgentTurn = (assistantMsgId: string) => {
    activeMsgIdRef.current = assistantMsgId;
    activeToolIdRef.current = null;
    setAgentRunning(true);
  };

  useEffect(() => {
    if (!isTauriEnvironment()) {
      console.info("[useAgentEvents] Running in web browser. Tauri IPC listeners bypassed.");
      return;
    }

    const unlisteners: Array<() => void> = [];

    async function setupListeners() {
      // 1. agent:token
      const unlistenToken = await listen<TokenPayload>("agent:token", (event) => {
        if (activeMsgIdRef.current) {
          appendToken(activeMsgIdRef.current, event.payload.token);
        }
      });
      unlisteners.push(unlistenToken);

      // 2. agent:tool_started
      const unlistenTool = await listen<ToolStartedPayload>("agent:tool_started", (event) => {
        if (activeMsgIdRef.current) {
          const toolId = `tool-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
          activeToolIdRef.current = toolId;
          const newToolEvent: ToolEvent = {
            id: toolId,
            toolName: event.payload.tool_name,
            detail: event.payload.detail,
            status: "running",
            timestamp: Date.now(),
          };
          addToolEvent(activeMsgIdRef.current, newToolEvent);
        }
      });
      unlisteners.push(unlistenTool);

      // 3. agent:stdout
      const unlistenStdout = await listen<StdoutPayload>("agent:stdout", (event) => {
        if (activeMsgIdRef.current && activeToolIdRef.current) {
          updateToolEvent(activeMsgIdRef.current, activeToolIdRef.current, {
            detail: event.payload.text,
            status: "running",
          });
        }
      });
      unlisteners.push(unlistenStdout);

      // 4. agent:diff_ready
      const unlistenDiff = await listen<DiffReadyPayload>("agent:diff_ready", (event) => {
        const approval: PendingApproval = {
          requestId: event.payload.request_id,
          type: "diff",
          filePath: event.payload.file_path,
          originalContent: event.payload.original_content,
          newContent: event.payload.new_content,
          unifiedDiff: event.payload.unified_diff,
        };
        setPendingApproval(approval);
      });
      unlisteners.push(unlistenDiff);

      // 5. agent:command_approval_request
      const unlistenCmd = await listen<CommandApprovalPayload>(
        "agent:command_approval_request",
        (event) => {
          const approval: PendingApproval = {
            requestId: event.payload.request_id,
            type: "command",
            command: event.payload.command,
            cwd: event.payload.cwd,
          };
          setPendingApproval(approval);
        }
      );
      unlisteners.push(unlistenCmd);

      // 6. agent:done
      const unlistenDone = await listen("agent:done", () => {
        if (activeMsgIdRef.current) {
          finishStreaming(activeMsgIdRef.current);
          if (activeToolIdRef.current) {
            updateToolEvent(activeMsgIdRef.current, activeToolIdRef.current, {
              status: "success",
            });
          }
        }
        setAgentRunning(false);
        activeMsgIdRef.current = null;
        activeToolIdRef.current = null;
      });
      unlisteners.push(unlistenDone);

      // 7. agent:error
      const unlistenErr = await listen<ErrorPayload>("agent:error", (event) => {
        if (activeMsgIdRef.current) {
          appendToken(
            activeMsgIdRef.current,
            `\n\n> ⚠️ **Error:** ${event.payload.error}`
          );
          finishStreaming(activeMsgIdRef.current);
          if (activeToolIdRef.current) {
            updateToolEvent(activeMsgIdRef.current, activeToolIdRef.current, {
              status: "error",
            });
          }
        }
        setAgentRunning(false);
        activeMsgIdRef.current = null;
        activeToolIdRef.current = null;
      });
      unlisteners.push(unlistenErr);
    }

    void setupListeners();

    return () => {
      unlisteners.forEach((u) => u());
    };
  }, [
    appendToken,
    finishStreaming,
    addToolEvent,
    updateToolEvent,
    setAgentRunning,
    setPendingApproval,
  ]);

  return { startAgentTurn };
}
