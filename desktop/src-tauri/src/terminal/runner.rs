use std::path::Path;
use std::process::Stdio;
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::process::Command;
use tokio::sync::Mutex;
use tokio::time::{timeout, Duration};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum RunnerError {
    #[error("Timed out after {0}s")]
    Timeout(u64),
    #[error("Spawn failed: {0}")]
    SpawnError(String),
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
}

#[derive(Debug, Clone)]
pub struct CommandOutput {
    pub stdout: String,
    pub stderr: String,
    pub exit_code: i32,
}

pub struct ProcessRunner;

impl ProcessRunner {
    pub async fn run<F>(
        command_str: &str,
        cwd: &Path,
        timeout_secs: u64,
        on_stdout_chunk: F,
    ) -> Result<CommandOutput, RunnerError>
    where
        F: Fn(String) + Send + 'static,
    {
        let on_stdout_chunk = Arc::new(Mutex::new(on_stdout_chunk));

        #[cfg(target_os = "windows")]
        let mut child = Command::new("powershell.exe")
            .args(["-NoProfile", "-Command", command_str])
            .current_dir(cwd)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .map_err(|e| RunnerError::SpawnError(e.to_string()))?;

        #[cfg(not(target_os = "windows"))]
        let mut child = Command::new("bash")
            .args(["-c", command_str])
            .current_dir(cwd)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .map_err(|e| RunnerError::SpawnError(e.to_string()))?;

        let stdout_pipe = child.stdout.take().expect("stdout piped");
        let stderr_pipe = child.stderr.take().expect("stderr piped");

        let stdout_buf = Arc::new(Mutex::new(String::new()));
        let stderr_buf = Arc::new(Mutex::new(String::new()));

        let sb = Arc::clone(&stdout_buf);
        let cb = Arc::clone(&on_stdout_chunk);
        let t1 = tokio::spawn(async move {
            let mut lines = BufReader::new(stdout_pipe).lines();
            while let Ok(Some(line)) = lines.next_line().await {
                let s = format!("{}\n", line);
                sb.lock().await.push_str(&s);
                cb.lock().await(s);
            }
        });

        let eb = Arc::clone(&stderr_buf);
        let t2 = tokio::spawn(async move {
            let mut lines = BufReader::new(stderr_pipe).lines();
            while let Ok(Some(line)) = lines.next_line().await {
                eb.lock().await.push_str(&format!("{}\n", line));
            }
        });

        let result = timeout(Duration::from_secs(timeout_secs), child.wait()).await;
        let exit_code = match result {
            Err(_) => {
                let _ = child.kill().await;
                return Err(RunnerError::Timeout(timeout_secs));
            }
            Ok(Err(e)) => return Err(RunnerError::Io(e)),
            Ok(Ok(s)) => s.code().unwrap_or(-1),
        };

        let _ = tokio::join!(t1, t2);

        let final_stdout = stdout_buf.lock().await.clone();
        let final_stderr = stderr_buf.lock().await.clone();

        Ok(CommandOutput {
            stdout: final_stdout,
            stderr: final_stderr,
            exit_code,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[tokio::test]
    async fn runs_echo_command_and_captures_stdout() {
        let dir = tempdir().unwrap();
        let collected = Arc::new(Mutex::new(Vec::new()));
        let col_clone = Arc::clone(&collected);

        let output = ProcessRunner::run(
            "Write-Output 'Hello from ProcessRunner'",
            dir.path(),
            10,
            move |chunk| {
                let col = Arc::clone(&col_clone);
                tokio::spawn(async move {
                    col.lock().await.push(chunk);
                });
            },
        )
        .await
        .unwrap();

        assert_eq!(output.exit_code, 0);
        assert!(output.stdout.contains("Hello from ProcessRunner"));
    }
}
