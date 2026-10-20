use serde_json::{json, Value};

pub fn get_tool_schemas() -> Vec<Value> {
    vec![
        json!({
            "type": "function",
            "function": {
                "name": "read_file",
                "description": "Read contents of a file within the workspace boundary with optional line filtering.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "path": {
                            "type": "string",
                            "description": "Relative path to the file within the workspace"
                        },
                        "start_line": {
                            "type": "integer",
                            "description": "Optional 1-based start line number to begin reading from"
                        },
                        "line_limit": {
                            "type": "integer",
                            "description": "Optional maximum number of lines to read"
                        }
                    },
                    "required": ["path"]
                }
            }
        }),
        json!({
            "type": "function",
            "function": {
                "name": "write_file",
                "description": "Write or create a complete file in the workspace. Shows a diff preview before applying.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "path": {
                            "type": "string",
                            "description": "Relative path to the file to create or overwrite"
                        },
                        "content": {
                            "type": "string",
                            "description": "Complete new contents of the file"
                        }
                    },
                    "required": ["path", "content"]
                }
            }
        }),
        json!({
            "type": "function",
            "function": {
                "name": "apply_diff",
                "description": "Replace an exact target snippet with replacement text in an existing workspace file.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "path": {
                            "type": "string",
                            "description": "Relative path to the existing file"
                        },
                        "target": {
                            "type": "string",
                            "description": "Exact text block in the file to be replaced"
                        },
                        "replacement": {
                            "type": "string",
                            "description": "Replacement text"
                        }
                    },
                    "required": ["path", "target", "replacement"]
                }
            }
        }),
        json!({
            "type": "function",
            "function": {
                "name": "run_command",
                "description": "Execute a shell command inside the workspace directory. Requires user approval before running.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "command": {
                            "type": "string",
                            "description": "Shell command to run (e.g. 'cargo check', 'npm test')"
                        },
                        "timeout_secs": {
                            "type": "integer",
                            "description": "Timeout in seconds (default: 60)"
                        }
                    },
                    "required": ["command"]
                }
            }
        }),
        json!({
            "type": "function",
            "function": {
                "name": "list_directory",
                "description": "List files and subdirectories in the specified workspace directory.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "path": {
                            "type": "string",
                            "description": "Relative directory path (empty string or '.' for workspace root)"
                        }
                    }
                }
            }
        }),
        json!({
            "type": "function",
            "function": {
                "name": "search_files",
                "description": "Search for text or patterns across workspace files, excluding build and dependency folders.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "Search term or substring to search for"
                        },
                        "path": {
                            "type": "string",
                            "description": "Optional subdirectory to restrict search to"
                        }
                    },
                    "required": ["query"]
                }
            }
        }),
    ]
}
