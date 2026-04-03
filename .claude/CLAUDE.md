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
│   │   ├── Billing/                    # Billing & subscription domain
│   │   ├── Platform/                   # Cross-cutting (services, stores, utilities)
│   │   ├── Tools/                      # Generator, Send, Import/Export
│   │   └── Vault/                      # Vault items domain
│   ├── Sourcery/                       # Mock generation config + output
│   └── UI/                             # UI layer (same subdirectories)
│       ├── Auth/
│       ├── Autofill/
│       ├── Billing/
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
│   └── Sourcery/                       # Mock generation config + output
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

**CRITICAL**: Do NOT add new top-level subdirectories to `Core/` or `UI/`. The fixed subdirectories are: `Auth/`, `Autofill/`, `Billing/`, `Platform/`, `Tools/`, `Vault/`.

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

## References

- `Docs/Architecture.md` — Architecture patterns and principles (authoritative)
- `Docs/Testing.md` — Testing guidelines and component-specific strategies (authoritative)

**Do not duplicate information from these files — reference them instead.**

