import { AppHeader } from "./components/AppHeader";
import { WorkspaceBar } from "./components/WorkspaceBar";
import { Sidebar } from "./components/Sidebar";
import { ProjectFileDrawer } from "./components/ProjectFileDrawer";
import { ChatArea } from "./components/ChatArea";
import { DiffReviewModal } from "./components/DiffReviewModal";
import { useChatStore } from "./store/chatStore";

export default function App() {
  const { activeMode, fileDrawerOpen } = useChatStore();

  return (
    <div
      style={{
        height: "100vh",
        display: "flex",
        flexDirection: "column",
        backgroundColor: "#131314",
        color: "#E3E3E3",
        overflow: "hidden",
        fontFamily: "'Google Sans', 'Roboto', sans-serif",
      }}
    >
      {/* Top application bar */}
      <AppHeader />

      {/* Workspace path bar */}
      <WorkspaceBar />

      {/* Main content area: Sidebar + Project Drawer + Chat Feed */}
      <div style={{ flex: 1, display: "flex", overflow: "hidden" }}>
        {/* Main navigation sidebar */}
        <Sidebar />

        {/* Collapsible Project File Drawer for Cowork Mode */}
        {activeMode === "cowork" && fileDrawerOpen && <ProjectFileDrawer />}

        {/* Chat / Agent workspace */}
        <main
          style={{
            flex: 1,
            display: "flex",
            flexDirection: "column",
            overflow: "hidden",
            backgroundColor: "#131314",
          }}
        >
          <ChatArea />
        </main>
      </div>

      {/* Interactive Human-In-The-Loop Diff & Command Review Modal */}
      <DiffReviewModal />
    </div>
  );
}
