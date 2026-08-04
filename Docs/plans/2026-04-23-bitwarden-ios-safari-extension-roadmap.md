# Bitwarden iOS Safari Extension Roadmap

> For Hermes: continue in small TDD slices, prefer upstream-style minimal diffs, and commit at each verified milestone.

**Goal:** Evolve the current iOS Safari Web Extension scaffold into a 1Password-class Safari experience with modern SwiftUI settings/setup surfaces and shared request-processing primitives.

**Current status:**
- `BitwardenSafariWebExtension` target scaffold exists and builds on iOS Simulator.
- Shared bridge/request models exist under `BitwardenShared/Core/SafariExtension/Models`.
- Background/content JS stubs exist and support request builders for fill/save/change-password/generate-password/setup.
- Settings routing already includes `.safariExtension` and `.safariExtensionSetup`.
- 2026-04-23: AutoFill settings now include a Safari Extension entry, with processor + ViewInspector coverage.

**Validated on 2026-04-23:**
- `BitwardenSafariWebExtension` scheme previously reached `** BUILD SUCCEEDED **`.
- `AutoFillProcessorTests` targeted run passed for Safari navigation.
- `AutoFillViewTests` targeted and broader AutoFill view/processor test runs passed.

**Known blocker:**
- Repeated broad Xcode builds can hit local disk pressure (`No space left on device`) under `~/Library/Developer/Xcode/DerivedData`. Clean before large rebuilds.

---

## Next slices

### Slice 1: Modernize Safari Extension settings UI
**Files:**
- Modify: `BitwardenShared/UI/Platform/Settings/Settings/AutoFill/SafariExtension/SafariExtensionView.swift`
- Modify: `BitwardenShared/UI/Platform/Settings/Settings/AutoFill/SafariExtension/SafariExtensionState.swift`
- Modify: `BitwardenShared/UI/Platform/Settings/Settings/AutoFill/SafariExtension/SafariExtensionAction.swift`
- Modify: `BitwardenShared/UI/Platform/Settings/Settings/AutoFill/SafariExtension/SafariExtensionProcessor.swift`
- Add/expand tests: `BitwardenShared/UI/Platform/Settings/Settings/AutoFill/SafariExtension/SafariExtensionProcessorTests.swift`

**Target outcome:**
- Replace temporary placeholder copy with a proper setup/status surface.
- Show activation state, short explanation of capabilities, and explicit setup CTA.
- Keep implementation SwiftUI-native and minimal.

### Slice 2: Improve setup flow semantics
**Files:**
- Modify: `BitwardenShared/UI/Platform/Settings/SettingsCoordinator.swift`
- Modify tests: `BitwardenShared/UI/Platform/Settings/SettingsCoordinatorTests.swift`

**Target outcome:**
- Preserve current `UIActivityViewController` bridge, but tighten callback/state semantics.
- Distinguish “opened setup UI” from “user confirmed enablement” as much as iOS APIs allow.

### Slice 3: Shared native request processing
**Files:**
- Modify: `BitwardenShared/Core/SafariExtension/Models/SafariExtensionRequestProcessor.swift`
- Add/expand tests in `BitwardenShared/Core/SafariExtension/Models/*Tests.swift`

**Target outcome:**
- Move from placeholder responses toward real shared logic for:
  - setup
  - generate password
  - fill candidate resolution
  - save/update/change-password classification

### Slice 4: Native bridge + JS contract tightening
**Files:**
- Modify: `BitwardenSafariWebExtension/SafariWebExtensionHandler.swift`
- Modify: `BitwardenSafariWebExtension/Application/Support/background.js`
- Modify: `BitwardenSafariWebExtension/Application/Support/content.js`

**Target outcome:**
- Stabilize message envelope handling.
- Support richer page-details payloads without widening permissions unnecessarily.
- Keep content script focused on page analysis and explicit user-triggered flows.

### Slice 5: Real feature wiring
**Files:**
- Likely shared autofill/action-helper areas under `BitwardenShared/Core/Autofill/**`
- Safari models under `BitwardenShared/Core/SafariExtension/**`
- Extension target handler/bridge files

**Target outcome:**
- End-to-end fill suggestions
- save/update login prompts
- change-password detection
- password generation insertion path

---

## Verification commands

### Targeted tests
```bash
xcodebuild -project Bitwarden.xcodeproj \
  -scheme Bitwarden \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  -only-testing:BitwardenSharedTests/AutoFillProcessorTests \
  -only-testing:BitwardenSharedViewInspectorTests/AutoFillViewTests \
  test CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO
```

### Safari extension build
```bash
xcodebuild -project Bitwarden.xcodeproj \
  -scheme BitwardenSafariWebExtension \
  -destination 'generic/platform=iOS Simulator' \
  build CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO
```

### If disk pressure appears
```bash
df -h ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/Bitwarden-*
```

---

## Commit discipline
- Commit each verified slice.
- Prefer messages like:
  - `feat: add safari extension entry to autofill settings`
  - `feat: modernize safari extension settings view`
  - `feat: expand safari extension request processing`

## Notes
- User preference is upstream-aligned minimal diff, not local-only wrappers.
- Keep the main path simple and Apple-native.
- Avoid over-expanding browser permissions early.