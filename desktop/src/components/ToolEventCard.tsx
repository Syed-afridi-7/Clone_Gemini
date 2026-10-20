import { FileText, Edit, Terminal, FolderTree, Search, CheckCircle, AlertCircle, Loader2 } from "lucide-react";
import { ToolEvent } from "../store/chatStore";

interface ToolEventCardProps {
  event: ToolEvent;
}

export function ToolEventCard({ event }: ToolEventCardProps) {
  const getIcon = () => {
    switch (event.toolName) {
      case "read_file":
        return <FileText size={14} className="text-blue-400" />;
      case "write_file":
      case "apply_diff":
        return <Edit size={14} className="text-purple-400" />;
      case "run_command":
        return <Terminal size={14} className="text-amber-400" />;
      case "list_directory":
        return <FolderTree size={14} className="text-emerald-400" />;
      case "search_files":
        return <Search size={14} className="text-cyan-400" />;
      default:
        return <FileText size={14} className="text-gray-400" />;
    }
  };

  const getStatusIndicator = () => {
    switch (event.status) {
      case "running":
        return <Loader2 size={13} className="text-blue-400 animate-spin" />;
      case "success":
        return <CheckCircle size={13} className="text-emerald-400" />;
      case "error":
        return <AlertCircle size={13} className="text-rose-400" />;
    }
  };

  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: "8px",
        padding: "4px 10px",
        borderRadius: "8px",
        backgroundColor: "#1E1F20",
        border: "1px solid #3C4043",
        fontSize: "0.78rem",
        color: "#E3E3E3",
        fontFamily: "'Google Sans', sans-serif",
        marginRight: "6px",
        marginBottom: "6px",
        maxWidth: "100%",
      }}
    >
      <span style={{ display: "flex", alignItems: "center" }}>{getIcon()}</span>
      <span style={{ fontWeight: 500, color: "#9AA0A6" }}>{event.toolName}:</span>
      <span
        style={{
          fontFamily: "monospace",
          fontSize: "0.75rem",
          overflow: "hidden",
          textOverflow: "ellipsis",
          whiteSpace: "nowrap",
          maxWidth: "280px",
        }}
        title={event.detail}
      >
        {event.detail}
      </span>
      <span style={{ display: "flex", alignItems: "center", marginLeft: "2px" }}>
        {getStatusIndicator()}
      </span>
    </div>
  );
}
