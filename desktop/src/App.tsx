import { AppHeader } from "./components/AppHeader";
import { WorkspaceBar } from "./components/WorkspaceBar";
import { Sidebar } from "./components/Sidebar";
import { ChatArea } from "./components/ChatArea";
import { DiffReviewModal } from "./components/DiffReviewModal";

export default function App() {
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
      {/* Top header bar */}
      <AppHeader />

      {/* Workspace path bar */}
      <WorkspaceBar />

      {/* Main content area: sidebar + chat */}
      <div style={{ flex: 1, display: "flex", overflow: "hidden" }}>
        {/* Left sidebar */}
        <Sidebar />

        {/* Chat content area */}
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

      {/* Diff and command human-in-the-loop modal */}
      <DiffReviewModal />
    </div>
  );
}
