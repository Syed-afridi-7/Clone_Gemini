use std::path::{Path, PathBuf};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum SandboxError {
    #[error("Path '{0}' is outside the workspace boundary")]
    PathOutsideWorkspace(PathBuf),
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Invalid path structure")]
    InvalidPath,
}

#[derive(Debug, Clone)]
pub struct SandboxGuard {
    workspace_root: PathBuf,
}

impl SandboxGuard {
    /// Create a new SandboxGuard rooted at the given path.
    /// The path must exist. Uses `dunce::canonicalize` to resolve
    /// Windows UNC paths and drive letter case normalization.
    pub fn new(root: &Path) -> Result<Self, SandboxError> {
        let canonical_root = dunce::canonicalize(root)?;
        Ok(Self { workspace_root: canonical_root })
    }

    /// Return the canonical workspace root path.
    pub fn workspace_root(&self) -> &Path {
        &self.workspace_root
    }

    /// Validate that `target` is within the workspace boundary.
    ///
    /// - Relative paths are resolved relative to `workspace_root`.
    /// - Absolute paths are checked directly.
    /// - Uses `dunce::canonicalize` on the parent when the target file
    ///   does not yet exist (allows validating paths for new files).
    /// - Returns the fully resolved canonical `PathBuf` on success.
    /// - Returns `Err(SandboxError::PathOutsideWorkspace)` if the resolved
    ///   path does not start with `workspace_root`.
    pub fn validate(&self, target: &Path) -> Result<PathBuf, SandboxError> {
        let full = if target.is_absolute() {
            target.to_path_buf()
        } else {
            self.workspace_root.join(target)
        };

        let resolved = if full.exists() {
            dunce::canonicalize(&full)?
        } else {
            // File doesn't exist yet (e.g. a new file to be created).
            // Canonicalize the parent, then append the filename.
            let parent = full.parent().ok_or(SandboxError::InvalidPath)?;
            let canon_parent = dunce::canonicalize(parent)?;
            let filename = full.file_name().ok_or(SandboxError::InvalidPath)?;
            canon_parent.join(filename)
        };

        if !resolved.starts_with(&self.workspace_root) {
            return Err(SandboxError::PathOutsideWorkspace(resolved));
        }

        Ok(resolved)
    }

    /// Convenience: read a file's contents after validating the path.
    pub fn read_file(&self, path: &Path) -> Result<String, SandboxError> {
        let safe_path = self.validate(path)?;
        let content = std::fs::read_to_string(&safe_path)?;
        Ok(content)
    }

    /// Convenience: write content to a file after validating the path.
    /// Creates parent directories if they don't exist.
    pub fn write_file(&self, path: &Path, content: &str) -> Result<(), SandboxError> {
        let safe_path = self.validate(path)?;
        if let Some(parent) = safe_path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(&safe_path, content)?;
        Ok(())
    }

    /// Convenience: list directory entries after validating the path.
    pub fn list_dir(&self, path: &Path) -> Result<Vec<PathBuf>, SandboxError> {
        let safe_path = self.validate(path)?;
        let entries = std::fs::read_dir(&safe_path)?
            .filter_map(|e| e.ok())
            .map(|e| e.path())
            .collect();
        Ok(entries)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn allows_paths_inside_workspace() {
        let dir = tempdir().unwrap();
        // Create a subdirectory so the path exists and can be canonicalized
        let sub = dir.path().join("src");
        std::fs::create_dir_all(&sub).unwrap();

        let guard = SandboxGuard::new(dir.path()).unwrap();

        // Validate relative path to existing subdir
        let result = guard.validate(Path::new("src"));
        assert!(result.is_ok(), "Expected Ok, got: {:?}", result);

        // Validate relative path to a new file (parent exists)
        let result2 = guard.validate(Path::new("src/main.rs"));
        assert!(result2.is_ok(), "Expected Ok for new file path, got: {:?}", result2);
    }

    #[test]
    fn blocks_traversal_above_workspace() {
        let dir = tempdir().unwrap();
        let guard = SandboxGuard::new(dir.path()).unwrap();

        // Attempt path traversal via ..
        let result = guard.validate(Path::new("../evil.txt"));
        assert!(
            matches!(result, Err(SandboxError::PathOutsideWorkspace(_))),
            "Expected PathOutsideWorkspace, got: {:?}",
            result
        );
    }

    #[test]
    fn blocks_absolute_path_outside_workspace() {
        let dir = tempdir().unwrap();
        let guard = SandboxGuard::new(dir.path()).unwrap();

        // An absolute path that is outside the workspace (sibling directory)
        let outside = dir.path().parent().unwrap().join("evil.txt");
        let result = guard.validate(&outside);
        assert!(
            matches!(result, Err(SandboxError::PathOutsideWorkspace(_))),
            "Expected PathOutsideWorkspace for absolute outside path, got: {:?}",
            result
        );
    }

    #[test]
    fn allows_reading_existing_file() {
        let dir = tempdir().unwrap();
        let guard = SandboxGuard::new(dir.path()).unwrap();

        // Write a file via raw fs then read via guard
        let file_path = dir.path().join("hello.txt");
        std::fs::write(&file_path, "hello world").unwrap();

        let content = guard.read_file(Path::new("hello.txt")).unwrap();
        assert_eq!(content, "hello world");
    }

    #[test]
    fn allows_writing_new_file() {
        let dir = tempdir().unwrap();
        let guard = SandboxGuard::new(dir.path()).unwrap();

        // Write via guard
        guard.write_file(Path::new("output.txt"), "test content").unwrap();

        // Verify the file was written
        let content = std::fs::read_to_string(dir.path().join("output.txt")).unwrap();
        assert_eq!(content, "test content");
    }
}
