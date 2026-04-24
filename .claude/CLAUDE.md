# Bitwarden iOS - Claude Code Configuration

Bitwarden's iOS repository containing two apps (Password Manager and Authenticator) built with Swift/SwiftUI, following a unidirectional data flow architecture with Coordinator-Processor-Store-View pattern.

### Acronyms
- **PM** / **BWPM**: Bitwarden Password Manager
- **BWA**: Bitwarden Authenticator
- **BWK**: Bitwarden Kit (shared framework)
- **BWTH**: Bitwarden Test Harness

## Overview

### What This Project Does
- Cross-platform password manager and TOTP authenticator for iOS, with app extensions for AutoFill, Action, Share, and watchOS companion
- Key interfaces: `Bitwarden` (main PM app), `Authenticator` (TOTP app), `BitwardenAutoFillExtension`, `BitwardenActionExtension`, `BitwardenShareExtension`, `BitwardenWatchApp`

### Key Concepts
- **Zero-knowledge architecture**: Server never receives unencrypted vault data; all encryption/decryption occurs client-side via the Bitwarden SDK
- **Unidirectional data flow**: View → Action/Effect → Store → Processor → State → View (never mutate state directly from views)
- **ServiceContainer**: Centralized dependency injection container conforming to composed `Has*` protocols
- **Coordinator pattern**: UIKit-based navigation management wrapping SwiftUI views
- **Bitwarden SDK (`BitwardenSdk`)**: Rust-based SDK handling cryptographic operations, cipher encryption/decryption, and key derivation

## Architecture & Patterns

### System Architecture

The app follows a layered architecture: Views send Actions/Effects to a Store, which delegates to a Processor (StateProcessor) for state mutations and async work. Processors use Repositories/Services for data operations and Coordinators for navigation. For detailed architecture diagrams and code examples, see `Docs/Architecture.md`.

### Code Organization

`Bitwarden/`, `Authenticator/` — app targets
`BitwardenShared/`, `AuthenticatorShared/`, `BitwardenKit/` — shared frameworks; each has `Core/` + `UI/` with fixed subdirs (see `Docs/Architecture.md` [Architecture Structure] for canonical domain list)
`AuthenticatorBridgeKit/`, `BitwardenResources/`, `Networking/` — support frameworks
`BitwardenAutoFillExtension/`, `BitwardenActionExtension/`, `BitwardenShareExtension/`, `BitwardenWatchApp/` — extensions
`Docs/`, `Scripts/`, `TestPlans/`, `Configs/`, `Sourcery/Templates/`, `project-*.yml` — configuration

**CRITICAL**: Do NOT add new top-level subdirectories to `Core/` or `UI/`. The fixed subdirectories are defined in `Docs/Architecture.md` under [Architecture Structure].

For key principles (unidirectional data flow, dependency injection, coordinator navigation, zero-knowledge), core patterns (Coordinator/Processor/State/View/Action/Effect files), adding new features, adding services/repositories, and common patterns, see `Docs/Architecture.md`.

## Data Models

CoreData entities are defined in `BitwardenShared/Core/Platform/Services/Stores/Bitwarden.xcdatamodeld`. Models follow the pattern: `Domain/`, `Enum/`, `Request/`, `Response/` subdirectories within each domain.

## Security & Configuration

### Security Rules

**MANDATORY — These rules have no exceptions:**

1. **Zero-Knowledge Preservation**: Never log, persist, or transmit unencrypted vault data. All encryption/decryption MUST use the Bitwarden SDK (`BitwardenSdk`).
2. **Keychain for Secrets**: Encryption keys, auth tokens, biometric keys, and PIN-derived keys MUST be stored in the iOS Keychain via `KeychainRepository`/`KeychainService`. Never use UserDefaults or CoreData for sensitive credentials.
3. **Input Validation**: Validate all user input using `InputValidator` utilities (`BitwardenKit/UI/Platform/Application/Utilities/InputValidator/`). Never trust external input.
4. **No Hardcoded Secrets**: API keys, tokens, and credentials must come from configuration or Keychain. Never commit secrets to the repository.
5. **Extension Memory Limits**: App extensions have strict memory limits. Monitor argon2id KDF memory usage — warn when `maxArgon2IdMemoryBeforeExtensionCrashing` (64 MB) is exceeded.

Key security components: `KeychainRepository`/`KeychainService` (Keychain operations), `InputValidator` (input validation), `ErrorReporter` (crash reporting with scrubbing), `NonLoggableError` (sensitive error protocol). Located in `Core/Auth/Services/` and `BitwardenKit/Core/Platform/`.

Security-critical constants are defined in `BitwardenShared/Core/Platform/Utilities/Constants.swift`. Consult this file for current values of unlock attempt limits, KDF parameters, token thresholds, and account limits.

Build configurations use xcconfig files in `Configs/` (Debug/Release per target). See `Configs/` directory for current files.

Xcode version requirement: see `.xcode-version` file

## Testing

Follow `Docs/Testing.md` (authoritative). See `testing-ios-code` skill for test-writing workflow. Snapshot tests are currently disabled — prefix function names with `disabletest_`.

## Code Style & Standards

Architecture and testing rules are in `Docs/Architecture.md` and `Docs/Testing.md` (authoritative). Key style rules are inline below.

### Formatting

| Tool | Config | Key Settings |
|------|--------|-------------|
| SwiftFormat | `.swiftformat` | 4-space indent, Swift 6.2 |
| SwiftLint | `.swiftlint.yml` | Custom rules: `todo_without_jira`, `weak_navigator`, `style_guide_font` |

```bash
mint run swiftformat .                  # Auto-fix formatting
mint run swiftformat --lint --lenient . # Check formatting
mint run swiftlint                      # Lint
typos                                   # Spell check
```

### Naming Conventions
- `camelCase` for: variables, functions, properties
- `PascalCase` for: types, protocols, enums, structs, classes
- `Has*` prefix for: dependency injection protocols (e.g., `HasAuthRepository`)
- `Default*` prefix for: default protocol implementations (e.g., `DefaultExampleService`)
- `Mock*` prefix for: test mocks (e.g., `MockExampleService`)
- Test naming: `test_<functionName>_<behaviorDescription>`

### Imports
- Group by: system frameworks, third-party, project modules
- Import `BitwardenSdk` for SDK types, `BitwardenKit` for shared utilities, `BitwardenResources` for shared assets, fonts, and localizations

### Comments & Documentation
- DocC format (`///`) for all public types and methods
- Exception: Protocol implementations (docs live in the protocol) and mocks
- Use `// MARK: -` sections to organize code within files
- JIRA ticket required in TODO comments (enforced by `todo_without_jira` SwiftLint rule)

## Patterns

### DO

- ✅ Use `StateProcessor` subclass for all feature processors
- ✅ Define `Services` typealias with only needed `Has*` protocols
- ✅ Use `coordinator.showErrorAlert(error:)` for consistent error presentation
- ✅ Use `store.binding(get:send:)` for SwiftUI bindings backed by store state
- ✅ Mark protocols with `// sourcery: AutoMockable` for mock generation
- ✅ Use `ServiceContainer.withMocks()` in tests
- ✅ Write snapshot tests in light, dark, AND large dynamic type modes (prefix disabled tests with `disable`)

### DON'T

- ❌ Mutate state directly from Views — always send Actions/Effects through the Store
- ❌ Put business logic in Coordinators — logic belongs in Processors
- ❌ Add new top-level subdirectories to `Core/` or `UI/` — use existing: `Auth/`, `Autofill/`, `Billing/`, `Platform/`, `Tools/`, `Vault/`
- ❌ Store sensitive data in UserDefaults or CoreData — use iOS Keychain via `KeychainRepository`
- ❌ Log or persist unencrypted vault data — zero-knowledge architecture must be preserved
- ❌ Use `any` type for protocol-based dependencies — use generics or `Has*` composition
- ❌ Create TODO comments without JIRA tickets — SwiftLint enforces `todo_without_jira`

## Build & Deploy

See `build-test-verify` skill for project generation, build commands, test execution, lint, format, code generation, common failures, and debug tips.

## Delivery Workflow

**You MUST use the following skills for code delivery tasks** — invoke via the Skill tool:

- **Before committing**: Run `perform-ios-preflight-checklist` to verify architecture, security, testing, and style compliance
- **When committing**: Use `committing-ios-changes` for commit message format, staging guidance, and commit creation
- **When creating a PR**: Use `creating-ios-pull-request` for PR title/body format, draft creation, and AI review label prompt
- **When labeling a PR**: Use `labeling-ios-changes` for change type (`t:*`) and app context (`app:*`) label selection
- **When reviewing code**: Use `reviewing-changes` for architecture, style, compilation, testing, and security review

## References

- `Docs/Architecture.md` — Architecture patterns and principles (authoritative)
- `Docs/Testing.md` — Testing guidelines and component-specific strategies (authoritative)

**Do not duplicate information from these files — reference them instead.**

## Skills & Commands

| Skill | Triggers |
|-------|---------|
| `refining-ios-requirements` | "refine requirements", "analyze ticket", "gap analysis" |
| `planning-ios-implementation` | "plan implementation", "design approach", "architecture plan" |
| `implementing-ios-code` | "implement", "write code", "add screen", "create feature" |
| `testing-ios-code` | "write tests", "add test coverage", "unit test" |
| `converting-xctest-to-swift-testing` | "convert to Swift Testing", "migrate XCTest", "xctest to swift testing" |
| `converting-mocks-to-automockable` | "convert mock", "migrate mock to AutoMockable", "replace bespoke mock" |
| `build-test-verify` | "build", "run tests", "lint", "format", "verify build" |
| `perform-ios-preflight-checklist` | "preflight", "self review", "ready to commit" |
| `committing-ios-changes` | "commit", "stage changes", "create commit" |
| `creating-ios-pull-request` | "create PR", "open pull request", "submit PR" |
| `labeling-ios-changes` | "label PR", "add labels", "categorize changes" |
| `reviewing-changes` | "review", "code review", "check PR" |

| Command | Usage |
|---------|-------|
| `/plan-ios-work <PM-XXXXX>` | Use the `ios-architect` agent (or this command) to fetch ticket → refine requirements → design implementation approach |
| `/work-on-ios <PM-XXXXX>` | Use the `ios-implementer` agent (or this command) for full workflow: implement → test → verify → preflight → commit → review → PR |
