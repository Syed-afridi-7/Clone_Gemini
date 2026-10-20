/**
 * Utility to check if the app is currently running inside the Tauri native desktop window,
 * or running inside a standard web browser (e.g. Vite dev server on http://localhost:1420).
 */
export function isTauriEnvironment(): boolean {
  if (typeof window === "undefined") return false;
  return Boolean(
    (window as unknown as { __TAURI_INTERNALS__?: unknown }).__TAURI_INTERNALS__ ||
    (window as unknown as { isTauri?: boolean }).isTauri
  );
}
