# Window Templates — Progress So Far

## Current Capabilities
- macOS menu bar app with status item and quick actions.
- Preset system with add/delete, selection, and persistence to Application Support as JSON.
- Preset editor UI with target list, bundle ID entry, and layout grid editor.
- Grid-based layout selection with drag-to-select and resize handles (24x16 grid).
- Apply action that moves/resizes the focused window of each target app via Accessibility APIs.
- Basic model tests for JSON round-trip and normalized rect mapping.

## Key Components
- App lifecycle and state: `AppEntry`, `AppDelegate`, `AppState`.
- Data model: `Preset`, `Target`, `NormalizedRect`.
- Services: `PresetStore` (persistence), `WindowManager` (AX apply), `AccessibilityPermissions`.
- UI: `MainWindow`, `PresetEditorView`, `GridEditorView`.

## Notes
- Window positioning currently uses the main screen’s visible frame.
- Applying a preset targets the focused window (or first window) per app bundle ID.

## Atomic Commits
- Keep commits small and single‑purpose so they’re faster to review and easier to reason about. citeturn0search9
- Prefer “atomic” commits that stand alone as stable, independent units (buildable/testable on their own). citeturn0search3
- Split unrelated changes (e.g., refactor vs. feature) into separate commits to keep reverts and reviews clean. citeturn0search2
