pub mod ollama_client;
pub mod tools;
pub mod approval;
pub mod orchestrator;

pub use ollama_client::{OllamaClient, OllamaMessage, ToolCall};
pub use approval::{ApprovalManager, ApprovalDecision};
pub use orchestrator::AgentOrchestrator;
