import { useState, useEffect } from "react";
import {
  Folder,
  FolderOpen,
  FileCode,
  FileText,
  ChevronRight,
  ChevronDown,
  RefreshCw,
  Search,
  PanelLeftClose,
  Code2,
} from "lucide-react";
import { useChatStore, FileNode } from "../store/chatStore";
import { isTauriEnvironment } from "../utils/tauri";

export function ProjectFileDrawer() {
  const {
    workspacePath,
    projectTree,
    treeLoading,
    setProjectTree,
    setTreeLoading,
    toggleFileDrawer,
    setWorkspacePath,
  } = useChatStore();

  const [filterText, setFilterText] = useState("");
  const [expandedDirs, setExpandedDirs] = useState<Record<string, boolean>>({});

  const loadTree = async () => {
    if (!workspacePath) return;
    setTreeLoading(true);
    try {
      if (isTauriEnvironment()) {
        const { invoke } = await import("@tauri-apps/api/core");
        const tree = await invoke<FileNode[]>("get_directory_tree");
        setProjectTree(tree);

        // Auto-expand top level folders
        const initialExpanded: Record<string, boolean> = {};
        tree.forEach((node) => {
          if (node.is_dir) {
            initialExpanded[node.path] = true;
          }
        });
        setExpandedDirs((prev) => ({ ...initialExpanded, ...prev }));
      } else {
        // Mock files for browser preview
        setProjectTree([
          {
            name: "src",
            path: "src",
            is_dir: true,
            children: [
              { name: "App.tsx", path: "src/App.tsx", is_dir: false },
              { name: "main.tsx", path: "src/main.tsx", is_dir: false },
              { name: "index.css", path: "src/index.css", is_dir: false },
            ],
          },
          {
            name: "src-tauri",
            path: "src-tauri",
            is_dir: true,
            children: [
              { name: "Cargo.toml", path: "src-tauri/Cargo.toml", is_dir: false },
              { name: "tauri.conf.json", path: "src-tauri/tauri.conf.json", is_dir: false },
            ],
          },
          { name: "package.json", path: "package.json", is_dir: false },
          { name: "README.md", path: "README.md", is_dir: false },
        ]);
      }
    } catch (err) {
      console.error("Failed to load project tree:", err);
    } finally {
      setTreeLoading(false);
    }
  };

  useEffect(() => {
    if (workspacePath) {
      void loadTree();
    }
  }, [workspacePath]);

  const handlePickFolder = async () => {
    try {
      if (isTauriEnvironment()) {
        const { open } = await import("@tauri-apps/plugin-dialog");
        const { invoke } = await import("@tauri-apps/api/core");
        const selected = await open({
          directory: true,
          multiple: false,
          title: "Select Project Workspace",
        });
        if (typeof selected === "string" && selected.trim()) {
          setWorkspacePath(selected);
          await invoke("set_workspace", { path: selected });
          void loadTree();
        }
      } else {
        const entered = prompt("Enter project directory path:", workspacePath || "E:\\gemini-clone");
        if (entered && entered.trim()) {
          setWorkspacePath(entered.trim());
        }
      }
    } catch (err) {
      console.error("Failed to pick folder:", err);
    }
  };

  const toggleDir = (path: string) => {
    setExpandedDirs((prev) => ({ ...prev, [path]: !prev[path] }));
  };

  const folderName = workspacePath
    ? workspacePath.replace(/\\/g, "/").split("/").filter(Boolean).pop() || "Workspace"
    : null;

  const renderFileIcon = (name: string) => {
    const ext = name.split(".").pop()?.toLowerCase();
    switch (ext) {
      case "rs":
        return <Code2 size={14} className="text-orange-400" />;
      case "ts":
      case "tsx":
      case "js":
      case "jsx":
        return <FileCode size={14} className="text-blue-400" />;
      case "dart":
        return <Code2 size={14} className="text-cyan-400" />;
      case "json":
      case "toml":
      case "yaml":
      case "yml":
        return <FileText size={14} className="text-amber-400" />;
      case "md":
        return <FileText size={14} className="text-purple-400" />;
      default:
        return <FileText size={14} className="text-gray-400" />;
    }
  };

  const filterNodes = (nodes: FileNode[], query: string): FileNode[] => {
    if (!query) return nodes;
    const lower = query.toLowerCase();
    return nodes
      .map((node) => {
        if (node.is_dir && node.children) {
          const matchingChildren = filterNodes(node.children, query);
          if (matchingChildren.length > 0 || node.name.toLowerCase().includes(lower)) {
            return { ...node, children: matchingChildren };
          }
        } else if (node.name.toLowerCase().includes(lower)) {
          return node;
        }
        return null;
      })
      .filter((n): n is FileNode => n !== null);
  };

  const renderTree = (nodes: FileNode[], level = 0) => {
    return nodes.map((node) => {
      const isExpanded = !!expandedDirs[node.path];

      if (node.is_dir) {
        return (
          <div key={node.path}>
            <div
              onClick={() => toggleDir(node.path)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: "6px",
                padding: `4px 8px 4px ${8 + level * 14}px`,
                cursor: "pointer",
                borderRadius: "6px",
                fontSize: "0.8rem",
                color: "#E3E3E3",
                userSelect: "none",
                transition: "background-color 0.1s",
              }}
              onMouseEnter={(e) =>
                ((e.currentTarget as HTMLDivElement).style.backgroundColor = "#282A2C")
              }
              onMouseLeave={(e) =>
                ((e.currentTarget as HTMLDivElement).style.backgroundColor = "transparent")
              }
            >
              {isExpanded ? (
                <ChevronDown size={13} style={{ opacity: 0.6 }} />
              ) : (
                <ChevronRight size={13} style={{ opacity: 0.6 }} />
              )}
              {isExpanded ? (
                <FolderOpen size={14} className="text-blue-400" />
              ) : (
                <Folder size={14} className="text-blue-400" />
              )}
              <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                {node.name}
              </span>
            </div>

            {isExpanded && node.children && node.children.length > 0 && (
              <div>{renderTree(node.children, level + 1)}</div>
            )}
          </div>
        );
      }

      return (
        <div
          key={node.path}
          style={{
            display: "flex",
            alignItems: "center",
            gap: "6px",
            padding: `4px 8px 4px ${24 + level * 14}px`,
            cursor: "pointer",
            borderRadius: "6px",
            fontSize: "0.8rem",
            color: "#9AA0A6",
            userSelect: "none",
            transition: "all 0.1s",
          }}
          title={node.path}
          onMouseEnter={(e) => {
            (e.currentTarget as HTMLDivElement).style.backgroundColor = "#282A2C";
            (e.currentTarget as HTMLDivElement).style.color = "#E3E3E3";
          }}
          onMouseLeave={(e) => {
            (e.currentTarget as HTMLDivElement).style.backgroundColor = "transparent";
            (e.currentTarget as HTMLDivElement).style.color = "#9AA0A6";
          }}
        >
          {renderFileIcon(node.name)}
          <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
            {node.name}
          </span>
        </div>
      );
    });
  };

  const displayedNodes = filterNodes(projectTree, filterText);

  return (
    <aside
      style={{
        width: "260px",
        backgroundColor: "#191A1B",
        borderRight: "1px solid #3C4043",
        display: "flex",
        flexDirection: "column",
        flexShrink: 0,
        height: "100%",
        overflow: "hidden",
      }}
    >
      {/* Drawer Header */}
      <div
        style={{
          padding: "10px 14px",
          borderBottom: "1px solid #3C4043",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          backgroundColor: "#1E1F20",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: "8px", overflow: "hidden" }}>
          <Folder size={16} className="text-blue-400" style={{ flexShrink: 0 }} />
          <span
            title={workspacePath}
            style={{
              fontSize: "0.85rem",
              fontWeight: 600,
              color: "#E3E3E3",
              fontFamily: "'Google Sans', sans-serif",
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
            }}
          >
            {folderName || "Project Files"}
          </span>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
          {workspacePath && (
            <button
              onClick={() => void loadTree()}
              disabled={treeLoading}
              title="Refresh project tree"
              style={{
                backgroundColor: "transparent",
                border: "none",
                color: "#9AA0A6",
                cursor: "pointer",
                padding: "4px",
                borderRadius: "4px",
                display: "flex",
                alignItems: "center",
              }}
            >
              <RefreshCw size={13} className={treeLoading ? "animate-spin" : ""} />
            </button>
          )}

          <button
            onClick={toggleFileDrawer}
            title="Collapse file drawer"
            style={{
              backgroundColor: "transparent",
              border: "none",
              color: "#9AA0A6",
              cursor: "pointer",
              padding: "4px",
              borderRadius: "4px",
              display: "flex",
              alignItems: "center",
            }}
          >
            <PanelLeftClose size={14} />
          </button>
        </div>
      </div>

      {/* Workspace Picker Button or Search Bar */}
      {workspacePath ? (
        <div style={{ padding: "8px 10px", borderBottom: "1px solid #282A2C" }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "6px",
              padding: "4px 8px",
              backgroundColor: "#131314",
              borderRadius: "6px",
              border: "1px solid #3C4043",
            }}
          >
            <Search size={13} style={{ color: "#9AA0A6", flexShrink: 0 }} />
            <input
              type="text"
              placeholder="Filter files..."
              value={filterText}
              onChange={(e) => setFilterText(e.target.value)}
              style={{
                backgroundColor: "transparent",
                border: "none",
                outline: "none",
                color: "#E3E3E3",
                fontSize: "0.78rem",
                width: "100%",
              }}
            />
          </div>
        </div>
      ) : (
        <div style={{ padding: "16px 14px", textAlign: "center" }}>
          <p style={{ color: "#9AA0A6", fontSize: "0.8rem", marginBottom: "12px" }}>
            No project folder connected.
          </p>
          <button
            onClick={handlePickFolder}
            style={{
              width: "100%",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: "6px",
              padding: "8px 12px",
              borderRadius: "8px",
              border: "none",
              background: "linear-gradient(135deg, #4285F4, #9B72CB)",
              color: "#FFFFFF",
              fontSize: "0.8rem",
              fontWeight: 500,
              cursor: "pointer",
            }}
          >
            <FolderOpen size={14} />
            Open Project
          </button>
        </div>
      )}

      {/* File Tree List */}
      <div style={{ flex: 1, overflowY: "auto", padding: "6px 4px" }}>
        {treeLoading ? (
          <div style={{ padding: "16px", color: "#9AA0A6", fontSize: "0.78rem", textAlign: "center" }}>
            Scanning project files...
          </div>
        ) : displayedNodes.length > 0 ? (
          renderTree(displayedNodes)
        ) : workspacePath ? (
          <div style={{ padding: "16px", color: "#9AA0A6", fontSize: "0.78rem", textAlign: "center" }}>
            {filterText ? "No matching files" : "Empty project"}
          </div>
        ) : null}
      </div>

      {/* Switch project footer */}
      {workspacePath && (
        <div style={{ padding: "8px 12px", borderTop: "1px solid #3C4043", backgroundColor: "#1E1F20" }}>
          <button
            onClick={handlePickFolder}
            style={{
              width: "100%",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: "6px",
              padding: "6px 10px",
              borderRadius: "6px",
              border: "1px solid #3C4043",
              backgroundColor: "transparent",
              color: "#9AA0A6",
              fontSize: "0.75rem",
              cursor: "pointer",
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
            <FolderOpen size={13} />
            Change Project Folder
          </button>
        </div>
      )}
    </aside>
  );
}
