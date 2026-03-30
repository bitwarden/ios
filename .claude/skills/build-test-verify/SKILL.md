---
name: build-test-verify
description: Build the project, run tests, lint, format, spell check, generate mocks, or verify the build passes for Bitwarden iOS. Use when asked to "build", "run tests", "lint", "format", "verify build", "check if it compiles", "run swiftlint", "run swiftformat", "generate mocks", or to execute any part of the build/test/verify pipeline.
---

# Build, Test, and Verify — Bitwarden iOS

## Initial Setup

```bash
brew bundle                  # Install Homebrew dependencies
./Scripts/bootstrap.sh       # Generate Xcode projects, install Mint packages, set up git hooks
```

Git hooks set up by `bootstrap.sh`:
- `post-checkout` / `post-merge` — automatically re-run `bootstrap.sh`

## Project Generation

`.xcodeproj` files are gitignored and must be generated before building:

```bash
mint run xcodegen --spec project-pm.yml    # Password Manager
mint run xcodegen --spec project-bwa.yml   # Authenticator
mint run xcodegen --spec project-bwk.yml   # BitwardenKit
mint run xcodegen --spec project-bwth.yml  # Test Harness
```

Or run all at once via `./Scripts/bootstrap.sh`.

## Building

```bash
./Scripts/build.sh project-pm.yml Bitwarden Simulator       # PM for simulator
./Scripts/build.sh project-bwa.yml Authenticator Simulator   # Authenticator for simulator
./Scripts/build.sh project-bwth.yml TestHarness Simulator    # Test Harness for simulator
./Scripts/build.sh project-pm.yml Bitwarden Device           # PM for device
```

## Running Tests

```bash
xcodebuild test \
  -workspace Bitwarden.xcworkspace \
  -scheme Bitwarden \
  -testPlan Bitwarden-Default \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Simulator must match `.test-simulator-device-name` and `.test-simulator-ios-version`.

CI runs all `-Default` test plans on PRs to `main`, commits to `main`, and release branches. Test execution order is randomized (`randomExecutionOrder: true`).

**Snapshot tests are currently disabled.** Do not run or re-record them. If you encounter a snapshot test, prefix the function name with `disable` (e.g., `disabletest_snapshot_defaultState`).

## Lint, Format, Spell Check

```bash
mint run swiftlint                        # Lint (custom rules: todo_without_jira, weak_navigator, style_guide_font)
mint run swiftformat .                    # Auto-fix formatting (4-space indent, Swift 6.2)
mint run swiftformat --lint --lenient .   # Check formatting without fixing
typos                                     # Spell check
```

SwiftLint and SwiftFormat run automatically as post-compile scripts (configured in `project-pm.yml`).

## Code Generation

Run automatically in pre-build phases; trigger manually when needed:

```bash
# Mock generation
mint run sourcery --config BitwardenShared/Sourcery/sourcery.yml
mint run sourcery --config AuthenticatorShared/Sourcery/sourcery.yml
mint run sourcery --config BitwardenKit/Sourcery/sourcery.yml

# Asset/localization code generation
mint run swiftgen config run --config swiftgen-bwr.yml   # BitwardenResources (most common)
mint run swiftgen config run --config swiftgen-pm.yml    # Password Manager
mint run swiftgen config run --config swiftgen-bwa.yml   # Authenticator
mint run swiftgen config run --config swiftgen-bwth.yml  # Test Harness
```

## Tooling Reference

| Tool | Config | Purpose |
|------|--------|---------|
| XcodeGen | `project-*.yml` | Generates `.xcodeproj` from YAML specs |
| Mint | `Mintfile` | Swift tool package manager |
| SwiftLint | `.swiftlint.yml` | Linting with custom rules |
| SwiftFormat | `.swiftformat` | Code formatting |
| Sourcery | `*/Sourcery/sourcery.yml` | Mock generation (`AutoMockable`) |
| SwiftGen | `swiftgen-*.yml` | Asset/localization code generation |
| typos | project config | Spell checking |
| Fastlane | `fastlane/Fastfile` | CI/CD automation |

## Common Failures

| Problem | Cause | Fix |
|---------|-------|-----|
| `.xcodeproj` not found | Files are gitignored | Run `./Scripts/bootstrap.sh` |
| `MockXxx` not found | Sourcery not run | Add `// sourcery: AutoMockable`, run Sourcery or build |
| Snapshot test runs | Snapshots are currently disabled | Prefix function name with `disable` (e.g., `disabletest_snapshot_defaultState`) |
| Extension crash on unlock | Argon2id KDF > 64 MB | Check `maxArgon2IdMemoryBeforeExtensionCrashing` in `Constants.swift` |
| SwiftLint TODO warning | Missing JIRA ticket | `// TODO: PM-12345 - description` |

## Debug Tips

- **Error reporting**: `ErrorReporter` protocol + `OSLogErrorReporter` for development
- **Flight recorder**: In-app logging for debugging production issues
- **SDK diagnostics**: Xcode console errors prefixed `BitwardenSdk`
- **Network debugging**: Set breakpoints in `APIService` implementations in `Networking/`
- **State debugging**: `print(subject.state)` in processor tests to inspect state changes
