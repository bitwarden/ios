# Bitwarden iOS Safari Extension Dev Loop Plan

> **For Hermes:** Use this as the default local workflow before adding heavier tooling. Keep the main path Apple-native, upstream-aligned, and verified with targeted tests.

**Goal:** Make Bitwarden Safari Web Extension work on `bitwarden/ios` feel fast enough for iterative feature work without introducing avoidable local-only complexity.

**Architecture:** Use a three-layer workflow. Layer 1 is the default inner loop: Xcode + Safari Web Inspector + targeted JS/Swift verification. Layer 2 is optional simulator streaming with `serve-sim` when AI/browser control or remote sharing is actually useful. Layer 3 is optional regression automation with Maestro after a flow becomes stable enough to encode as E2E.

**Tech Stack:** Xcode 26.4.1, iOS Simulator 26.4.1, Safari Web Inspector, `xcodebuild`, `simctl`, Node test runner, optional `serve-sim`, optional Maestro.

---

## Live-validated baseline on this machine

Validated on 2026-04-30 in `~/_dev/ios`:

- `xcodebuild -version` → Xcode 26.4.1 / Build 17E202
- Available simulator includes `iPhone 17 Pro` on `OS=26.4.1`
- `node BitwardenSafariWebExtension/Application/Support/content.node-test.js` → passed
- `xcodebuild build -project Bitwarden.xcodeproj -scheme BitwardenSafariWebExtension -destination 'generic/platform=iOS Simulator' ...` → `** BUILD SUCCEEDED **`
- Targeted Safari shared tests passed:
  - `SafariExtensionRequestProcessorTests`
  - `SafariExtensionResponseTests`
  - `SafariExtensionBridgeCodecTests`

Important: this environment needs the exact simulator patch version `26.4.1`, not `26.4`.

---

## Default recommendation

### Use this as the primary loop
1. Edit Swift/JS in the existing Safari extension files.
2. Run the fast JS node test.
3. Run targeted Swift tests for Safari shared models/processors.
4. Build the Safari extension target.
5. Verify live in Simulator with Safari Web Inspector.
6. Prefer the local fixture pages in `Docs/safari-extension-dev-fixtures/` over third-party sites for repeatable repro.

### Use these only when needed
- Add `serve-sim` when you want AI/browser/remote interaction with the simulator.
- Add Maestro when a manual validation flow has stabilized and is worth encoding as repeatable E2E.

---

## Files most relevant to this loop

### Swift shared logic
- `BitwardenShared/Core/SafariExtension/Models/SafariExtensionRequestProcessor.swift`
- `BitwardenShared/Core/SafariExtension/Models/SafariExtensionResponse.swift`
- `BitwardenShared/Core/SafariExtension/Models/SafariExtensionBridgeCodec.swift`
- `BitwardenShared/Core/SafariExtension/Models/SafariExtensionSubmissionAction.swift`

### Swift tests
- `BitwardenShared/Core/SafariExtension/Models/SafariExtensionRequestProcessorTests.swift`
- `BitwardenShared/Core/SafariExtension/Models/SafariExtensionResponseTests.swift`
- `BitwardenShared/Core/SafariExtension/Models/SafariExtensionBridgeCodecTests.swift`

### Extension bridge/runtime
- `BitwardenSafariWebExtension/SafariWebExtensionHandler.swift`
- `BitwardenSafariWebExtension/SafariWebExtensionBridge.swift`
- `BitwardenSafariWebExtension/Application/Support/content.js`
- `BitwardenSafariWebExtension/Application/Support/background.js`
- `BitwardenSafariWebExtension/Application/Support/content.node-test.js`

### Settings UI
- `BitwardenShared/UI/Platform/Settings/Settings/AutoFill/SafariExtension/SafariExtensionView.swift`
- `BitwardenShared/UI/Platform/Settings/Settings/AutoFill/SafariExtension/SafariExtensionProcessor.swift`
- `BitwardenShared/UI/Platform/Settings/Settings/AutoFill/SafariExtension/SafariExtensionView+ViewInspectorTests.swift`

---

## Task 1: Reuse the known-good fast verification commands

**Objective:** Establish a minimal command set that is fast enough to run on nearly every Safari-extension slice.

**Files:**
- No code changes
- Reference: `Docs/plans/2026-04-30-bitwarden-ios-safari-dev-loop.md`

**Step 1: Run JS contract tests**

Run:
```bash
cd ~/_dev/ios
node BitwardenSafariWebExtension/Application/Support/content.node-test.js
```

Expected:
```text
content node tests passed
```

**Step 2: Run targeted Swift tests for Safari shared logic**

Run:
```bash
cd ~/_dev/ios
xcodebuild test \
  -project Bitwarden.xcodeproj \
  -scheme Bitwarden \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  -only-testing:BitwardenSharedTests/SafariExtensionRequestProcessorTests \
  -only-testing:BitwardenSharedTests/SafariExtensionResponseTests \
  -only-testing:BitwardenSharedTests/SafariExtensionBridgeCodecTests \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO
```

Expected:
```text
** TEST SUCCEEDED **
```

**Step 3: Build the extension target**

Run:
```bash
cd ~/_dev/ios
xcodebuild build \
  -project Bitwarden.xcodeproj \
  -scheme BitwardenSafariWebExtension \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO
```

Expected:
```text
** BUILD SUCCEEDED **
```

**Step 4: Use this decision table**

- JS-only edit in `content.js` / `background.js`:
  - always run node test
  - usually run extension build
- Shared Swift logic edit in `SafariExtension*` models:
  - run targeted Swift tests
  - then extension build
- Settings SwiftUI edit:
  - run matching ViewInspector / processor tests
  - then extension build

---

## Task 2: Make Safari Web Inspector the default live debugging surface

**Objective:** Use the Apple-native debugger instead of adding a custom remote-control layer too early.

**Files:**
- No code changes
- Live targets are the running simulator and extension process

**Step 1: Build and launch the app in Simulator from Xcode**

Use the `Bitwarden` app target and the booted `iPhone 17 Pro (26.4.1)` simulator.

**Step 2: Open Safari in the simulator and navigate to a reproducible test page**

Use a page that exercises the exact flow under development:
- login page for fill/update
- signup page for save-new-login
- password-change page for generated-password follow-up

**Step 3: Attach Safari Web Inspector from macOS Safari**

Use Safari Develop menu on the Mac to inspect the simulator page / extension context.

Expected use:
- inspect DOM field classification
- inspect content-script console output
- inspect message payloads crossing the bridge
- verify whether failure is in JS page analysis or Swift native response generation

**Step 4: Keep the failure split explicit**

- If the DOM/page-details are wrong → fix `content.js`
- If page-details are right but response is wrong → fix `SafariExtensionRequestProcessor.swift`
- If response is right but UI action panel is wrong → fix JS rendering / bridge application logic

---

## Task 3: Use a reproducible inner loop per slice

**Objective:** Prevent broad builds and vague manual retesting from slowing down iteration.

**Files:**
- Modify depending on slice
- Test the smallest matching set

**Step 1: For shared processor work, stay inside this slice**

Typical files:
- `BitwardenShared/Core/SafariExtension/Models/SafariExtensionRequestProcessor.swift`
- `BitwardenShared/Core/SafariExtension/Models/SafariExtensionRequestProcessorTests.swift`

Loop:
```bash
node BitwardenSafariWebExtension/Application/Support/content.node-test.js
xcodebuild test -project Bitwarden.xcodeproj -scheme Bitwarden \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  -only-testing:BitwardenSharedTests/SafariExtensionRequestProcessorTests \
  CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO
xcodebuild build -project Bitwarden.xcodeproj -scheme BitwardenSafariWebExtension \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO
```

**Step 2: For bridge/response schema work, use the schema-focused slice**

Typical files:
- `SafariExtensionResponse.swift`
- `SafariExtensionBridgeCodec.swift`
- corresponding `*Tests.swift`

Loop:
```bash
node BitwardenSafariWebExtension/Application/Support/content.node-test.js
xcodebuild test -project Bitwarden.xcodeproj -scheme Bitwarden \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  -only-testing:BitwardenSharedTests/SafariExtensionResponseTests \
  -only-testing:BitwardenSharedTests/SafariExtensionBridgeCodecTests \
  CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO
xcodebuild build -project Bitwarden.xcodeproj -scheme BitwardenSafariWebExtension \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO
```

**Step 3: For settings UI work, stay in ViewInspector/processor scope**

Suggested command shape:
```bash
xcodebuild test -project Bitwarden.xcodeproj -scheme Bitwarden \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  -only-testing:BitwardenSharedTests/SafariExtensionProcessorTests \
  -only-testing:BitwardenSharedViewInspectorTests/SafariExtensionViewTests \
  CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO
```

**Step 4: Only broaden scope after the slice is green**

Do not start with full-suite `Bitwarden` tests for normal Safari extension iteration.

---

## Task 4: Keep simulator state reset cheap and scriptable

**Objective:** Use Apple CLI tools for the parts that do not need visual inspection.

**Files:**
- No repo changes required

**Step 1: Reuse the known booted simulator**

Check devices:
```bash
xcrun simctl list devices available
```

**Step 2: Capture screenshots for visual diff / bug reports**

```bash
xcrun simctl io booted screenshot /tmp/bitwarden-safari-debug.png
```

**Step 3: Capture a short recording when repro is timing-sensitive**

```bash
xcrun simctl io booted recordVideo --force /tmp/bitwarden-safari-debug.mov
```

Stop with `Ctrl-C` after the repro.

**Step 4: Use UI toggles when appearance matters**

```bash
xcrun simctl ui booted appearance dark
xcrun simctl ui booted appearance light
```

Use this for settings-view regressions and Safari surface contrast checks.

---

## Task 5: Add `serve-sim` only as an optional second-layer tool

**Objective:** Use simulator streaming when it adds something real, not as the default for every edit.

**Files:**
- No repo changes required at first

**When to use it:**
- you want an AI/browser agent to interact with the simulator
- you want to share a live simulator session remotely
- you want a browser-visible simulator surface without screen sharing

**When not to use it:**
- ordinary JS/Swift debugging where Web Inspector is enough
- issues already reproducible locally in Xcode + Simulator

**Step 1: Start it ad hoc**

```bash
npx serve-sim
```

Expected from upstream README:
- preview server on `http://localhost:3200`
- simulator framebuffer stream + control channel

**Step 2: Treat it as a visibility/control layer only**

Still keep:
- Safari Web Inspector for web/extension debugging
- targeted tests for correctness
- `xcodebuild` for build verification

**Step 3: Do not build local-only repo coupling around it yet**

No wrapper scripts, no repo config changes, no custom integration until repeated use proves it deserves a committed workflow.

---

## Task 6: Add Maestro only after a manual flow is stable

**Objective:** Encode the expensive repeated flows as E2E only after the underlying product behavior stops moving every hour.

**Files:**
- Scaffolded under `.maestro/` for local smoke flows
- Extend later if Maestro becomes part of the regular regression path

**Best candidate flows:**
- generated password on signup page → save-new-login suggestion appears
- generated password on change-password page → update-password suggestion appears
- matched-login fill flow on a login page

**Adoption rule:**
- First prove the flow manually with Web Inspector + targeted tests
- Then encode the stable flow in Maestro
- Do not use Maestro as the first debugger for bridge/schema bugs

---

## Pitfalls

- Use `OS=26.4.1`, not `26.4`, in `xcodebuild -destination`.
- Broad Xcode test/build runs can consume a lot of DerivedData space.
- `serve-sim` does not replace Safari Web Inspector.
- If you add new Swift files, remember project generation may need to be refreshed via the repo’s `xcodegen` flow.
- Keep the default path simple: Apple-native first, extra tooling second.

---

## Verification bundle for future slices

Run this exact sequence before calling a Safari-extension slice “done”:

```bash
cd ~/_dev/ios
node BitwardenSafariWebExtension/Application/Support/content.node-test.js
xcodebuild test \
  -project Bitwarden.xcodeproj \
  -scheme Bitwarden \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  -only-testing:BitwardenSharedTests/SafariExtensionRequestProcessorTests \
  -only-testing:BitwardenSharedTests/SafariExtensionResponseTests \
  -only-testing:BitwardenSharedTests/SafariExtensionBridgeCodecTests \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO
xcodebuild build \
  -project Bitwarden.xcodeproj \
  -scheme BitwardenSafariWebExtension \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO
```

Expected final outcomes:
- `content node tests passed`
- `** TEST SUCCEEDED **`
- `** BUILD SUCCEEDED **`

---

## Suggested next implementation slice

If continuing immediately, the next high-value slice should be:

1. pick one real page classification gap in `SafariExtensionRequestProcessor`
2. add a failing targeted Swift test
3. make the smallest processor fix
4. verify with the fast command bundle above
5. confirm behavior live in Simulator with Safari Web Inspector

That keeps the main path simple, verified, and upstream-friendly.