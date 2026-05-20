---
description: Build the Bitwarden iOS app, capture all compiler and lint warnings, categorize them into Swift 6 concurrency vs actionable, and interactively fix the actionable ones.
argument-hint: "[scheme] — defaults to Bitwarden"
---

# Audit Build Warnings: $ARGUMENTS

## Setup

Resolve the build scheme:
- If `$ARGUMENTS` is provided, use it as the scheme name (e.g., `Authenticator`, `TestHarness`).
- Otherwise default to `Bitwarden`.

Read simulator config — always read these files, never hardcode values:
```bash
DEVICE=$(tr -d '\n' < .test-simulator-device-name)
OS=$(tr -d '\n' < .test-simulator-ios-version)
```

## Phase 1: Build & Capture

Run the build and capture all output to a temp file:
```bash
xcodebuild build \
  -project <SCHEME>.xcodeproj \
  -scheme <SCHEME> \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=$OS" \
  -configuration Debug \
  2>&1 | tee /tmp/bitwarden_build_output.txt
```

Confirm the build result (`** BUILD SUCCEEDED **` vs `** BUILD FAILED **`). If it failed, report errors and stop — don't proceed to warning fixes.

Extract unique warnings (exclude timestamp lines starting with the year):
```bash
grep -E "warning:" /tmp/bitwarden_build_output.txt \
  | grep -v "^20[0-9][0-9]" \
  | sort -u
```

## Phase 2: Categorize

Classify every warning into one of these buckets:

### 🔴 Swift 6 Concurrency (always skip — tracked separately)
Keywords that identify these: `Sendable`, `non-Sendable`, `actor-isolated`, `nonisolated`, `@preconcurrency`, `main actor`, `Sendable closure`, `sendable closure`, `data races`, `Swift 6 language mode`

### 🟡 Actionable (candidates for fixing)
Everything else, sub-divided by fix type:
- **SwiftFormat** — `trailingSpace`, `trailingCommas`, `redundantSelf`, `lineLength` (from SwiftFormat)
- **SwiftLint** — `file_length`, `line_length`, `superfluous_disable_command`, `unused_closure_parameter`, `redundantSelf`, `orphaned_doc_comment`, etc.
- **Swift compiler** — deprecation warnings, always-true/always-false casts, protocol near-matches
- **Retroactive conformance** — `extension declares a conformance of imported type … to imported protocol`

### ⚪ Default Skips (propose to user unless they override)
These categories are typically intentional or in third-party code — default to skipping them:
- **Vendored / third-party code**: any file under paths like `BitwardenWatchShared/MessagePack/`, `**/Vendor/`, or other vendored directories
- **Deprecated API warnings** where the replacement requires non-trivial SDK changes (flag these for the user to decide)
- **Always-true / always-false casts** (`'as' test is always true`) — may be intentional defensive guards
- **Protocol near-match** warnings in third-party code

## Phase 3: Report

Write a temporary markdown report to `/tmp/build_warnings_report.md` (NOT to `Docs/` or any tracked directory — this is an ephemeral audit artifact).

Structure:
1. **Summary table**: count per category
2. **Swift 6 Concurrency section**: list all warnings grouped by sub-theme (actor isolation, Sendable captures, etc.) — presented for awareness, not fixing
3. **Actionable section**: list all non-Swift 6 warnings grouped by type (SwiftFormat, SwiftLint, compiler)
4. **Default skips section**: list warnings proposed to skip with rationale
5. **Fix feasibility notes**: auto-fixable vs manual vs complex

Present the summary table to the user inline (don't make them open the file).

## Phase 4: Confirm Exclusions

Ask the user one question:

> "Here are the **[N] actionable warnings** I found. By default I'll skip: [list default-skip items].
> Which additional warnings (if any) would you like to exclude before I fix the rest?"

Accept free-form input, or "none" / "proceed as-is".

Record the final exclusion list.

## Phase 5: Fix

Apply fixes in this exact order:

### Step 1 — SwiftFormat auto-fix (ALWAYS first, BEFORE reading any files)
```bash
mint run swiftformat .
```
This handles: trailing spaces, trailing commas, redundantSelf, import ordering. Note which files were changed.

**Important**: Run `swiftformat` BEFORE using the `Read` tool on any target file — running it after you've read a file will cause a state sync warning.

### Step 2 — Manual fixes (targeted, one file at a time)
For each remaining actionable warning not in the exclusion list:

- **Superfluous `// swiftlint:disable`**: delete the disable comment line
- **Unused closure parameter**: replace the named parameter with `_`
- **Line length violation** in a comment: break the comment line; maintain indentation/continuation markers
- **Line length violation** in a function signature: break to multi-line. **Always add a trailing comma on the last parameter** when doing so — Swift 6.2 + `trailingCommas` rule require it
- **file_length violation**: add `// swiftlint:disable file_length` as the **very first line** of the file, before any imports or doc comments. Do NOT place it between a doc comment and its declaration (this would trigger `orphaned_doc_comment`)
- **Retroactive conformance** (`extension declares a conformance of imported type X to imported protocol Y`): add `@retroactive` before the protocol name in the extension conformance list

### Step 3 — Verify
Run a targeted SwiftLint + SwiftFormat lint check on only the files that were changed:
```bash
mint run swiftlint lint <file1> <file2> ... | grep -E "warning:|error:"
mint run swiftformat --lint --lenient <file1> <file2> ...
```
If new violations appear, fix them before proceeding.

## Phase 6: Cleanup & Summary

1. Delete the temp report: `rm /tmp/build_warnings_report.md`
2. Delete the build output: `rm /tmp/bitwarden_build_output.txt`
3. Present a final summary:
   - How many warnings were fixed (by type)
   - Which warnings were intentionally skipped (and why)
   - How many Swift 6 concurrency warnings remain (with a note that these require a dedicated effort)
4. Suggest next steps:
   - Commit the fixes using `bitwarden-delivery-tools:committing-changes`
   - If there are 10+ Swift 6 warnings, suggest creating a PM ticket to track them

## Guard Rails

**Never fix Swift 6 concurrency warnings** in this workflow — they require actor annotations, `@preconcurrency` imports, or protocol-level changes that need intentional review, not automated fixing.

**Never commit the temp report** (`/tmp/build_warnings_report.md`) — it is for interactive review only and must be deleted at the end.

**Never modify `BitwardenSdk` types directly** — they come from the Rust SDK. Use `@retroactive` conformances instead.

**Stop and surface** any warning that would require changing a public API, moving a file between modules, or touching the Bitwarden SDK — these need human review before fixing.
