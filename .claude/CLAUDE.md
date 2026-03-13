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

```
├── Bitwarden/                          # Password Manager app target
│   └── Application/
├── Authenticator/                      # Authenticator app target
│   └── Application/
├── BitwardenShared/                    # Main PM shared framework
│   ├── Core/                           # Data & business logic
│   │   ├── Auth/                       # Authentication domain
│   │   ├── Autofill/                   # AutoFill domain
│   │   ├── Platform/                   # Cross-cutting (services, stores, utilities)
│   │   ├── Tools/                      # Generator, Send, Import/Export
│   │   └── Vault/                      # Vault items domain
│   ├── Sourcery/                       # Mock generation config + output
│   └── UI/                             # UI layer (same subdirectories)
│       ├── Auth/
│       ├── Autofill/
│       ├── Platform/
│       ├── Tools/
│       └── Vault/
├── AuthenticatorShared/                # Authenticator shared framework
│   ├── Core/                           # Same structure as BitwardenShared
│   ├── Sourcery/                       # Mock generation config + output
│   └── UI/
├── BitwardenKit/                       # Common functionality across both apps
│   ├── Core/
│   │   └── Platform/Services/          # Has* protocols, ServiceContainer base
│   ├── Sourcery/                       # Mock generation config + output
│   └── UI/
│       └── Platform/Application/
│           └── Utilities/              # Store, Processor, Coordinator, Alert
├── BitwardenResources/                 # Shared assets, fonts, localizations
├── AuthenticatorBridgeKit/             # PM ↔ Authenticator communication
├── Networking/                         # URLSession-based networking (Swift package)
├── BitwardenAutoFillExtension/         # AutoFill Credential Provider extension
├── BitwardenActionExtension/           # Action extension (autofill via share sheet)
├── BitwardenShareExtension/            # Share extension (create Sends)
├── BitwardenWatchApp/                  # watchOS companion
├── GlobalTestHelpers/                  # Shared test utilities
├── Sourcery/Templates/                 # Shared Sourcery Stencil templates
├── Configs/                            # xcconfig files (Debug/Release per target)
├── Scripts/                            # Build, bootstrap, CI scripts
├── TestPlans/                          # Xcode test plans
├── Docs/                               # Architecture.md, Testing.md
└── project-*.yml                       # XcodeGen project specs
```

**CRITICAL**: Do NOT add new top-level subdirectories to `Core/` or `UI/`. The fixed subdirectories are: `Auth/`, `Autofill/`, `Platform/`, `Tools/`, `Vault/`.

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

### Authentication & Authorization

- **Login flows**: Email+password, SSO, SSO+TDE, passwordless (device approval), biometric unlock, PIN unlock
- **Key derivation**: PBKDF2 or Argon2id (configurable per account)
- **Token lifecycle**: Access tokens refreshed preemptively 5 minutes before expiry (`tokenRefreshThreshold`)
- **Biometric auth**: Touch ID / Face ID unlock via Keychain access control flags
- **Multi-account**: Up to 5 accounts with per-user data isolation (CoreData `userId` scoping)

## Testing

**You MUST follow testing guidelines in `Docs/Testing.md`** (authoritative source for test structure, naming, templates, decision matrix, running tests, and simulator configuration). Snapshot tests are currently disabled — prefix function names with `disable`.

## Code Style & Standards

### Core Directives

**You MUST follow these directives at all times:**

1. **Adhere to Architecture**: All code modifications MUST follow patterns in `Docs/Architecture.md`
2. **Follow Code Style**: ALWAYS follow https://contributing.bitwarden.com/contributing/code-style/swift
3. **Follow Testing Guidelines**: Tests MUST follow guidelines in `Docs/Testing.md`
4. **Best Practices**: Follow Swift / SwiftUI best practices (value over reference types, guard clauses, extensions, protocol-oriented programming)
5. **Document Everything**: All code requires DocC documentation except protocol property/function implementations (docs live in the protocol) and mocks
6. **Dependency Management**: Use `ServiceContainer` as established in the project
7. **Use Established Patterns**: Leverage existing components before creating new ones
8. **File References**: Use `file_path:line_number` format when referencing code

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

### Pre-build Scripts
Configured in `project-pm.yml`:
- SwiftLint runs as post-compile script
- SwiftFormat lint runs as post-compile script
- Sourcery mock generation runs as pre-build phase
- SwiftGen asset code generation runs as pre-build phase

## Patterns

### DO

- ✅ Use `StateProcessor` subclass for all feature processors
- ✅ Define `Services` typealias with only needed `Has*` protocols
- ✅ Use `coordinator.showErrorAlert(error:)` for consistent error presentation
- ✅ Use `store.binding(get:send:)` for SwiftUI bindings backed by store state
- ✅ Mark protocols with `// sourcery: AutoMockable` for mock generation
- ✅ Co-locate test files with implementation files
- ✅ Use `ServiceContainer.withMocks()` in tests
- ✅ Write snapshot tests in light, dark, AND large dynamic type modes
- ✅ Use `guard` clauses for early returns
- ✅ Prefer value types (structs/enums) over reference types where appropriate
- ✅ Use existing UI components from `BitwardenKit/UI/` before creating new ones

### DON'T

- ❌ Mutate state directly from Views — always send Actions/Effects through the Store
- ❌ Put business logic in Coordinators — logic belongs in Processors
- ❌ Add new top-level subdirectories to `Core/` or `UI/` — use existing: `Auth/`, `Autofill/`, `Platform/`, `Tools/`, `Vault/`
- ❌ Store sensitive data in UserDefaults or CoreData — use iOS Keychain via `KeychainRepository`
- ❌ Log or persist unencrypted vault data — zero-knowledge architecture must be preserved
- ❌ Skip input validation — use `InputValidator` utilities
- ❌ Use `any` type for protocol-based dependencies — use generics or `Has*` composition
- ❌ Create TODO comments without JIRA tickets — SwiftLint enforces `todo_without_jira`
- ❌ Skip DocC documentation on new public types/methods
- ❌ Use real services/network calls in tests — always use mocks
- ❌ Hardcode credentials or API keys

## Deployment

### Building

```bash
# Generate Xcode projects (required — .xcodeproj files are gitignored)
mint run xcodegen --spec project-pm.yml    # Password Manager
mint run xcodegen --spec project-bwa.yml   # Authenticator
mint run xcodegen --spec project-bwk.yml   # BitwardenKit
mint run xcodegen --spec project-bwth.yml  # Test Harness

# Build
./Scripts/build.sh project-pm.yml Bitwarden Simulator   # PM for simulator
./Scripts/build.sh project-bwa.yml Authenticator Device  # Authenticator for device
```

### Initial Setup

```bash
brew bundle                    # Install Homebrew dependencies
./Scripts/bootstrap.sh         # Generate Xcode projects, install Mint packages, set up git hooks
```

### Git Hooks

Set up automatically by `bootstrap.sh`:
- `post-checkout`: Runs `bootstrap.sh` to regenerate projects
- `post-merge`: Runs `bootstrap.sh` to regenerate projects

### Code Generation

Runs automatically in pre-build phases, but can be triggered manually:
```bash
mint run sourcery --config BitwardenShared/Sourcery/sourcery.yml   # Generate mocks
mint run swiftgen config run --config swiftgen-pm.yml              # Generate asset code
```

### CI/CD

- **Fastlane**: `fastlane/Fastfile` for build automation
- CI runs all `-Default` test plans on pull requests to `main`, commits to `main`, and release branches
- Test execution order is randomized (`randomExecutionOrder: true`)

### Key Tooling

| Tool | Config File | Purpose |
|------|------------|---------|
| XcodeGen | `project-*.yml` | Generates Xcode projects from YAML specs |
| Mint | `Mintfile` | Swift tool package manager |
| SwiftLint | `.swiftlint.yml` | Linting with custom rules |
| SwiftFormat | `.swiftformat` | Code formatting (4-space indent, Swift 6.2) |
| Sourcery | `*/Sourcery/sourcery.yml` | Mock generation (`AutoMockable`) |
| SwiftGen | `swiftgen-*.yml` | Asset/localization code generation |
| Fastlane | `fastlane/Fastfile` | CI/CD automation |

## Troubleshooting

### Common Issues

#### Missing Xcode Projects

**Problem**: `.xcodeproj` and `.xcworkspace` files are gitignored and not found after checkout.

**Solution**: Run `./Scripts/bootstrap.sh` or generate manually with `mint run xcodegen --spec project-pm.yml`.

#### Snapshot Test Failures

**Problem**: Snapshot tests fail with image differences.

**Solution**:
1. Verify simulator matches `.test-simulator-device-name` and `.test-simulator-ios-version`
2. If visual changes are intentional, re-record: `RECORD_MODE=1 xcodebuild test -testPlan Bitwarden-Snapshot ...`
3. Commit new snapshot images with your changes

#### Mock Generation Missing

**Problem**: `MockExampleService` not found after adding new protocol.

**Solution**:
1. Ensure protocol has `// sourcery: AutoMockable` annotation
2. Run `mint run sourcery --config BitwardenShared/Sourcery/sourcery.yml`
3. Or build the project (Sourcery runs in pre-build phase)

#### App Extension Memory Crashes

**Problem**: AutoFill or Action extension crashes during vault unlock.

**Solution**: Check KDF settings — Argon2id with memory > 64 MB (`maxArgon2IdMemoryBeforeExtensionCrashing`) can exceed extension memory limits. The app warns users about this.

#### SwiftLint TODO Warning

**Problem**: SwiftLint flags TODO comments.

**Solution**: Include a JIRA ticket reference: `// TODO: PM-12345 - Description of work to do`

### Debug Tips

- **Error reporting**: `ErrorReporter` protocol with `OSLogErrorReporter` for development logging
- **Flight recorder**: In-app logging system for debugging production issues
- **SDK diagnostics**: Check Xcode console for SDK errors (prefix: `BitwardenSdk`)
- **Network debugging**: Networking layer in `Networking/` Swift package — set breakpoints in `APIService` implementations
- **State debugging**: Add `print(subject.state)` in processor tests to inspect state changes

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
| `build-test-verify` | "build", "run tests", "lint", "format", "verify build" |
| `perform-ios-preflight-checklist` | "preflight", "self review", "ready to commit" |
| `committing-ios-changes` | "commit", "stage changes", "create commit" |
| `creating-ios-pull-request` | "create PR", "open pull request", "submit PR" |
| `labeling-ios-changes` | "label PR", "add labels", "categorize changes" |
| `reviewing-changes` | "review", "code review", "check PR" |

| Command | Usage |
|---------|-------|
| `/plan-ios-work <PM-XXXXX>` | Fetch ticket → refine requirements → create design doc |
| `/work-on-ios <PM-XXXXX>` | Full workflow: plan → implement → test → verify → commit → PR |

