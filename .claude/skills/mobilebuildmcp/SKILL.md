---
name: mobilebuildmcp
description: Drive the iOS Simulator (build-and-run, install, launch, log capture, screenshots, and UI automation) through MobileBuildMCP tools. Use before calling any MobileBuildMCP tool, or when asked to run the app on a simulator, inspect the UI, take screenshots, or automate taps, swipes, and typing, including entering text with symbols such as emails, URLs, and passwords. For CI-style builds, lint, format, or full test-suite runs, use `build-test-verify` instead.
---

# MobileBuildMCP

Prefer MobileBuildMCP tools over raw `xcodebuild`, `xcrun`, or `simctl` for interactive simulator build/run/test and UI-driving work. This does not override the commands prescribed elsewhere in this repo: the clean-build troubleshooting in `.claude/CLAUDE.md` and the raw invocations in `build-test-verify`, `fixing-flaky-tests`, `audit-build-warnings`, and `evaluating-sdk-internal-updates` remain authoritative. The one raw command this skill itself prescribes is the clipboard paste in "UI Automation", because MobileBuildMCP has no clipboard tool.

Capabilities:
- Session defaults: Configure project, scheme, simulator, and device defaults to avoid repetitive parameters
- Project discovery: Find Xcode projects/workspaces, list schemes, inspect build settings
- Simulator workflows: Build, run, test, install, and launch apps on iOS simulators; manage simulator state (boot, erase, location, appearance)
- Device workflows: Build, test, install, and launch apps on physical devices with code signing
- macOS workflows: Build, run, and test macOS applications
- Log capture: Stream and capture logs from simulators and devices
- LLDB debugging: Attach debugger, set breakpoints, inspect stack traces and variables, execute LLDB commands
- UI automation: Capture screenshots, inspect view hierarchy with coordinates, perform taps/swipes/gestures, type text, press hardware buttons
- SwiftPM: Build, run, test, and manage Swift Package Manager projects
- Project scaffolding: Generate new iOS/macOS project templates

Only simulator workflow tools are enabled by default. If capabilities like device, macOS, debugging, or UI automation are not available, the user must configure MobileBuildMCP to enable them. See https://github.com/getsentry/xcodebuildmcp.com/blob/main/app/docs/_content/configuration.mdx for workflow configuration.

## Step 1: Establish Session Context

- Call `session_show_defaults` before the first build/run/test action in a session.
- Use `discover_projs` only when defaults show missing or incorrect project/workspace context.
- Do not run discovery speculatively or in parallel with `session_show_defaults`.
- If defaults or `discover_projs` show no project/workspace, the gitignored `.xcodeproj` has not been generated yet. Run `./Scripts/bootstrap.sh` (or `mint run xcodegen --spec project-pm.yml`), then re-check defaults. See the `build-test-verify` skill.
- For simulator run intent, prefer `build_run_sim` instead of separate build then run calls.
- Do not chain build-only (`build_sim`) then `build_run_sim` unless the user explicitly requests both.

## Troubleshooting: Workflow-Scoped Tool Availability

- Not all tools are enabled by default; tool availability depends on enabled workflows.
- If a tool is expected but missing, check enabled workflows first.
- Update enabled workflows in `.mobilebuildmcp/config.yaml`, then ask user to reload/restart the session to surface refreshes.

## Reporting

- Return the active defaults context used for execution (project/workspace, scheme, simulator/device).
- For failures, include the exact failing step and the next actionable command/tool call.

## UI Automation (when driving the UI)

### Always call `snapshot_ui` before interacting
Use the coordinates and element refs it returns. Don't guess coordinates from screenshots.

### Typing text: `type_text` is layout-dependent
`type_text` sends key codes through the **host Mac's keyboard layout**, so symbols can come out wrong.
Example on a Spanish ISO layout: `6d3b72c8+ios-login@bw.example` was typed as `6d3b72c8¡ios'login"bw.example`.

- Plain letters and digits are safe on any layout.
- Anything containing symbols (`+ @ . _ - ' " / \ : # & = ?`) is **not** safe unless the layout is verified. This includes emails, URLs, passwords, and TOTP URIs.

**Check the layout before typing symbols** (read-only):

```bash
defaults read com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID
```

- `com.apple.keylayout.US` (or `USExtended`): `type_text` is safe for symbols.
- Anything else (e.g. `Spanish-ISO`): use the clipboard-paste workflow below.

**Always read the field back with `snapshot_ui` after typing and compare it to the intended value.** The layout check can miss cases such as an input source that changes mid-session. Don't proceed on an unverified field.

### Entering text with symbols: clipboard paste (uses raw `simctl`)
1. `xcrun simctl pbcopy <simulator-id>` with the value on stdin (get `<simulator-id>` from `session_show_defaults`).
2. `long_press` the target field to open the edit menu.
3. `snapshot_ui`, then `touch` (down, then up) on the **Paste** item.
4. `snapshot_ui` again to verify the field contents.

### Edit-menu items (Paste, Select All, Copy) are not buttons
They appear in `snapshot_ui` as plain text rows, so `tap` rejects them. Use `touch` (down, then up) at their coordinates.

### Test data
Prefer test values without symbols where the flow allows it. When symbols are required, use the paste workflow unless the layout check passed.

**Never type or paste real vault credentials, production account passwords, or live TOTP URIs.** Use throwaway test-account values only: the simulator pasteboard persists and can sync to the host Mac clipboard.
