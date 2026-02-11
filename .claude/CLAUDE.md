# Bitwarden iOS - Claude Code Configuration

Bitwarden's iOS repository containing two apps (Password Manager and Authenticator) built with Swift/SwiftUI, following a unidirectional data flow architecture with Coordinator-Processor-Store-View pattern.

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

```
    User Interaction
         ↓
    SwiftUI View (sends Action/Effect)
         ↓
    Store (ObservableObject bridge)
         ↓
    Processor (StateProcessor<State, Action, Effect>)
    ├── receive(_:) → sync state mutation / coordinator.navigate()
    └── perform(_:) → async work via Repository/Service → state mutation
         ↓                           ↓
    State (published back to View)   Coordinator (navigation)
                                     ├── navigate(to: Route)
                                     ├── showAlert(_:)
                                     ├── showErrorAlert(error:)
                                     └── showToast(_:)
```

```
    Core Layer (data & business logic)
    ┌──────────────────────────────────────────────────┐
    │  Repositories (data synthesis, exposed to UI)     │
    │  ├── AuthRepository, VaultRepository, ...         │
    │  ├── Compose multiple Services                    │
    │  └── Expose AsyncPublishers for streaming data    │
    ├──────────────────────────────────────────────────┤
    │  Services (single-responsibility wrappers)        │
    │  ├── CipherService, NFCReaderService, ...         │
    │  └── Wrap SDK, OS, or network calls               │
    ├──────────────────────────────────────────────────┤
    │  Data Stores (persistence)                        │
    │  ├── AppSettingsStore (UserDefaults)               │
    │  ├── DataStore (CoreData)                         │
    │  └── KeychainRepository (iOS Keychain)            │
    ├──────────────────────────────────────────────────┤
    │  Models (Domain, Enum, Request, Response)         │
    └──────────────────────────────────────────────────┘
```

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
│   └── UI/                             # UI layer (same subdirectories)
│       ├── Auth/
│       ├── Autofill/
│       ├── Platform/
│       ├── Tools/
│       └── Vault/
├── AuthenticatorShared/                # Authenticator shared framework
│   ├── Core/                           # Same structure as BitwardenShared
│   └── UI/
├── BitwardenKit/                       # Common functionality across both apps
│   ├── Core/
│   │   └── Platform/Services/          # Has* protocols, ServiceContainer base
│   └── UI/
│       └── Platform/Application/
│           └── Utilities/              # Store, Processor, Coordinator, Alert
├── BitwardenResources/                 # Shared assets, fonts, localizations
├── AuthenticatorBridgeKit/             # PM ↔ Authenticator communication
├── Networking/                         # URLSession-based networking (Swift package)
├── BitwardenAutoFillExtension/         # AutoFill Credential Provider extension
├── BitwardenActionExtension/           # Action extension (share sheet)
├── BitwardenShareExtension/            # Share extension (create Sends)
├── BitwardenWatchApp/                  # watchOS companion
├── GlobalTestHelpers/                  # Shared test utilities
├── Configs/                            # xcconfig files (Debug/Release per target)
├── Scripts/                            # Build, bootstrap, CI scripts
├── TestPlans/                          # Xcode test plans
├── Docs/                               # Architecture.md, Testing.md
└── project-*.yml                       # XcodeGen project specs
```

**CRITICAL**: Do NOT add new top-level subdirectories to `Core/` or `UI/`. The fixed subdirectories are: `Auth/`, `Autofill/`, `Platform/`, `Tools/`, `Vault/`.

### Key Principles

1. **Unidirectional Data Flow**: State mutations only occur in Processors via `receive(_:)` (sync) or `perform(_:)` (async). Views never mutate state directly.
2. **Protocol-Based Dependency Injection**: All services/repositories are protocols. `ServiceContainer` conforms to composed `Has*` protocols. Components declare local `Services` typealiases limiting access.
3. **Coordinator-Driven Navigation**: Coordinators own navigation containers (UINavigationController). Business logic stays in Processors; Coordinators handle navigation only.
4. **Zero-Knowledge**: All encryption/decryption via Bitwarden SDK. Keys stored in iOS Keychain. Server never sees plaintext.

### Core Patterns

#### Unidirectional Data Flow (Coordinator-Processor-Store-View)

**Purpose**: Predictable state management with clear separation between UI, logic, and navigation.

Each feature typically has these files:

| File | Purpose |
|------|---------|
| `*Coordinator.swift` | Navigation, creates child views/coordinators via Module protocol |
| `*Processor.swift` | State management, handles Actions (sync) and Effects (async) |
| `*State.swift` | View state definition (must be `Equatable`) |
| `*View.swift` | SwiftUI view, sends actions/effects to Store |
| `*Action.swift` | Synchronous user interactions (enum) |
| `*Effect.swift` | Asynchronous user interactions (enum) |

#### Dependency Injection via Has* Protocol Composition

**Purpose**: Fine-grained dependency access control without exposing the entire `ServiceContainer`.

**Implementation** (`BitwardenShared/Core/Platform/Services/Services.swift`):
```swift
// Aggregate typealias composes all Has* protocols
typealias Services = HasAPIService
    & HasAuthRepository
    & HasConfigService
    // ... 50+ protocols

// Individual Has* protocols
protocol HasAuthRepository {
    var authRepository: AuthRepository { get }
}
```

**Usage** (in Processor/Coordinator):
```swift
final class ExampleProcessor: StateProcessor<ExampleState, ExampleAction, ExampleEffect> {
    typealias Services = HasExampleRepository & HasErrorReporter

    private let services: Services

    init(coordinator: AnyCoordinator<ExampleRoute, Void>, services: Services, state: ExampleState) {
        self.services = services
        super.init(state: state)
    }
}
```

#### Router Pattern (Complex Navigation Logic)

**Purpose**: Separate navigation decision-making from Coordinators when routing involves async state checks.

**Implementation** (`BitwardenKit/UI/Platform/Application/Utilities/Router.swift`):
```swift
protocol Router<Event, Route> {
    func handleAndRoute(_ event: Event) async -> Route
}
```

**Usage** (see `BitwardenShared/UI/Auth/AuthRouter.swift`):
```swift
// Coordinators with HasRouter automatically delegate events to the router
// router.handleAndRoute(event) → returns Route → coordinator navigates to Route
```

#### Module Pattern (Coordinator Factories)

**Purpose**: `DefaultAppModule` provides a single entry point for creating all coordinators, injecting services without passing them through coordinator hierarchy.

**Implementation** (`BitwardenShared/UI/Platform/Application/AppModule.swift`):
```swift
protocol AppModule {
    func makeAppCoordinator(/* params */) -> AnyCoordinator<AppRoute, AppEvent>
}
```

---

## Development Guide

### Adding a New Feature (UI Screen)

**1. Define the State** (`UI/<Domain>/<Feature>/<Feature>State.swift`)
```swift
struct ExampleState: Equatable {
    var data: String?
    var isLoading = false
    var isToggleOn = false
}
```

**2. Define Actions and Effects**
```swift
// ExampleAction.swift
enum ExampleAction: Equatable {
    case dismissTapped
    case toggleChanged(Bool)
}

// ExampleEffect.swift
enum ExampleEffect: Equatable {
    case loadData
    case appeared
}
```

**3. Define Routes** (`UI/<Domain>/<Feature>/<Feature>Route.swift`)
```swift
enum ExampleRoute: Equatable {
    case detail(id: String)
    case dismiss
}
```

**4. Implement the Processor** (`UI/<Domain>/<Feature>/<Feature>Processor.swift`)
```swift
// MARK: - ExampleProcessor

/// The processor used to manage state and handle actions for the example screen.
///
final class ExampleProcessor: StateProcessor<ExampleState, ExampleAction, ExampleEffect> {
    // MARK: Types

    typealias Services = HasExampleRepository & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<ExampleRoute, Void>

    /// The services for this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `ExampleProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services for this processor.
    ///   - state: The initial state of the processor.
    ///
    init(coordinator: AnyCoordinator<ExampleRoute, Void>, services: Services, state: ExampleState) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: ExampleAction) {
        switch action {
        case .dismissTapped:
            coordinator.navigate(to: .dismiss)
        case let .toggleChanged(newValue):
            state.isToggleOn = newValue
        }
    }

    override func perform(_ effect: ExampleEffect) async {
        switch effect {
        case .loadData:
            do {
                state.data = try await services.exampleRepository.loadData()
            } catch {
                coordinator.showErrorAlert(error: error)
            }
        case .appeared:
            await perform(.loadData)
        }
    }
}
```

**5. Implement the View** (`UI/<Domain>/<Feature>/<Feature>View.swift`)
```swift
struct ExampleView: View {
    @ObservedObject var store: Store<ExampleState, ExampleAction, ExampleEffect>

    var body: some View {
        // Build UI from store.state, send actions via store.send(), effects via store.perform()
        .task { await store.perform(.appeared) }
    }
}
```

**6. Implement the Coordinator** (`UI/<Domain>/<Feature>/<Feature>Coordinator.swift`)
```swift
final class ExampleCoordinator: Coordinator, HasStackNavigator {
    typealias Event = Void
    typealias Services = HasExampleRepository & HasErrorReporter

    private let services: Services
    private(set) weak var stackNavigator: StackNavigator?

    func navigate(to route: ExampleRoute, context: AnyObject?) {
        switch route {
        case let .detail(id):
            showDetail(id: id)
        case .dismiss:
            stackNavigator?.dismiss()
        }
    }

    private func showExample() {
        let processor = ExampleProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: ExampleState()
        )
        let view = ExampleView(store: Store(processor: processor))
        stackNavigator?.push(view)
    }
}
```

**7. Register in Module** — Add factory method to the appropriate Module protocol and implement in `DefaultAppModule`.

**8. Write Tests** — Co-locate test files with implementation. See Testing section.

**9. Add DocC Documentation** — All public types/methods require DocC docs except protocol implementations and mocks.

### Adding a New Service/Repository

**1. Define the Protocol** (`Core/<Domain>/Services/<ServiceName>.swift`)
```swift
// sourcery: AutoMockable
protocol ExampleService {
    func fetchData() async throws -> [ExampleModel]
}
```

**2. Implement** (`Core/<Domain>/Services/<ServiceName>.swift` or separate file on multiple implementations for the same protocol)
```swift
final class DefaultExampleService: ExampleService {
    private let apiService: APIService
    // ...
}
```

**3. Add Has* Protocol** (`Core/Platform/Services/Services.swift`)
```swift
protocol HasExampleService {
    var exampleService: ExampleService { get }
}
```

**4. Register in ServiceContainer** — Add property and include in initializer.

**5. Run Sourcery** to generate mocks:
```bash
mint run sourcery --config BitwardenShared/Sourcery/sourcery.yml
```

### Common Patterns

#### Error Handling (Processors)

```swift
override func perform(_ effect: ExampleEffect) async {
    switch effect {
    case .loadData:
        do {
            state.data = try await services.exampleRepository.loadData()
        } catch {
            // Standard pattern: coordinator shows error alert
            coordinator.showErrorAlert(error: error)
        }
    }
}
```

#### Alert Presentation

```swift
// Via coordinator (most common)
coordinator.showAlert(.networkResponseError(error) {
    // retry action
    await self.perform(.loadData)
})

// Custom alert
coordinator.showAlert(Alert(
    title: Localizations.warning,
    message: Localizations.confirmDelete,
    alertActions: [
        AlertAction(title: Localizations.cancel, style: .cancel),
        AlertAction(title: Localizations.delete, style: .destructive) { /* action */ },
    ]
))
```

#### Store Bindings in Views

```swift
Toggle(
    Localizations.toggleExample,
    isOn: store.binding(
        get: \.isToggleOn,
        send: ExampleAction.toggleChanged
    )
)
```

---

## Data Models

### CoreData Entities

Persisted in `BitwardenShared/Core/Platform/Services/Stores/Bitwarden.xcdatamodeld`:

| Entity | Purpose |
|--------|---------|
| `CipherData` | Encrypted vault items (logins, cards, identities, notes) |
| `CollectionData` | Organizational collections |
| `DomainData` | Domain settings per user |
| `FolderData` | User folders |
| `OrganizationData` | Organization membership data |

All entities follow the pattern: `id` + `modelData` (Binary, JSON-encoded) + `userId`, with uniqueness constraints on `(userId, id)`.

**Data Model Pattern** (`BitwardenShared/Core/Vault/Models/Data/CipherData.swift`):
```swift
class CipherData: NSManagedObject, ManagedUserObject, CodableModelData {
    typealias Model = CipherDetailsResponseModel
    @NSManaged var id: String?
    @NSManaged var modelData: Data?
    @NSManaged var userId: String?
}
```

### Key Domain Types

| Type | Location | Purpose |
|------|----------|---------|
| `Cipher` / `CipherView` | BitwardenSdk | SDK types for vault items |
| `CipherDetailsResponseModel` | Core/Vault/Models/Response | API response for cipher details |
| `Account` | Core/Auth/Models/Domain | User account with profile, tokens, settings |
| `ErrorResponseModel` | BitwardenKit/Core/Auth/Models/Response | Standard API error response |
| `ServerError` | BitwardenKit/Core/Platform/Services/API/Errors | Network error enum (.error, .validationError) |

### Model Organization

- `Domain/` — Core business types used throughout the app
- `Enum/` — Enumeration types
- `Request/` — API request body models
- `Response/` — API response models (decoded from JSON)

---

## Security & Configuration

### Security Rules

**MANDATORY — These rules have no exceptions:**

1. **Zero-Knowledge Preservation**: Never log, persist, or transmit unencrypted vault data. All encryption/decryption MUST use the Bitwarden SDK (`BitwardenSdk`).
2. **Keychain for Secrets**: Encryption keys, auth tokens, biometric keys, and PIN-derived keys MUST be stored in the iOS Keychain via `KeychainRepository`/`KeychainService`. Never use UserDefaults or CoreData for sensitive credentials.
3. **Input Validation**: Validate all user input using `InputValidator` utilities (`BitwardenKit/UI/Platform/Application/Utilities/InputValidator/`). Never trust external input.
4. **No Hardcoded Secrets**: API keys, tokens, and credentials must come from configuration or Keychain. Never commit secrets to the repository.
5. **Extension Memory Limits**: App extensions have strict memory limits. Monitor argon2id KDF memory usage — warn when `maxArgon2IdMemoryBeforeExtensionCrashing` (64 MB) is exceeded.

### Security Functions

| Component | Location | Purpose |
|-----------|----------|---------|
| `KeychainRepository` | `Core/Auth/Services/KeychainRepository.swift` | High-level Keychain operations for auth tokens, keys |
| `KeychainService` | `Core/Auth/Services/KeychainService.swift` | Low-level Keychain CRUD with access control |
| `KeychainServiceError` | `BitwardenKit/Core/Platform/Models/Enum/` | Error types: `.accessControlFailed`, `.keyNotFound`, `.osStatusError` |
| `InputValidator` | `BitwardenKit/UI/Platform/Application/Utilities/InputValidator/` | Input validation with `InputValidationError` |
| `NonLoggableError` | `BitwardenKit/Core/Platform/Services/API/Errors/` | Protocol for errors that should not be logged (sensitive data) |
| `ErrorReporter` | `BitwardenKit/Core/Platform/Services/ErrorReporter/` | Crash reporting with sensitive data scrubbing |

### Security Constants (`BitwardenShared/Core/Platform/Utilities/Constants.swift`)

| Constant | Value | Purpose |
|----------|-------|---------|
| `maxUnlockUnsuccessfulAttempts` | 5 | Lock after failed unlock attempts |
| `minimumPbkdf2IterationsForUpgrade` | 600,000 | Minimum PBKDF2 iterations before forced upgrade |
| `pbkdf2Iterations` | 600,000 | Default KDF iterations |
| `kdfArgonMemory` | 64 MB | Default Argon2id memory |
| `kdfArgonParallelism` | 4 | Default Argon2id parallelism |
| `tokenRefreshThreshold` | 5 minutes | Preemptive token refresh window |
| `loginRequestTimeoutMinutes` | 15 | Passwordless login request expiry |
| `maxAccounts` | 5 | Maximum concurrent accounts |

### Environment Configuration

Build configurations use xcconfig files in `Configs/`:

| Config | Purpose |
|--------|---------|
| `Bitwarden-Debug.xcconfig` | PM app debug settings |
| `Bitwarden-Release.xcconfig` | PM app release settings |
| `BitwardenAutoFillExtension.xcconfig` | AutoFill extension settings |
| `BitwardenActionExtension-*.xcconfig` | Action extension settings |

Xcode version requirement: `.xcode-version` (currently `26.1.1`)

### Authentication & Authorization

- **Login flows**: Email+password, SSO, SSO+TDE, passwordless (device approval), biometric unlock, PIN unlock
- **Key derivation**: PBKDF2 or Argon2id (configurable per account)
- **Token lifecycle**: Access tokens refreshed preemptively 5 minutes before expiry (`tokenRefreshThreshold`)
- **Biometric auth**: Touch ID / Face ID unlock via Keychain access control flags
- **Multi-account**: Up to 5 accounts with per-user data isolation (CoreData `userId` scoping)

---

## Testing

### Core Directives

**You MUST follow these directives when writing or analyzing tests:**
- Follow guidelines in `Docs/Testing.md` (authoritative source)
- Every type containing logic **must** be tested
- Test files are **co-located** with implementation files

### Test Structure

```
# Tests live alongside implementation (not in separate directory):
BitwardenShared/UI/Platform/Application/
├── AppProcessor.swift
├── AppProcessorTests.swift              # Unit tests
├── AppView.swift
├── AppView+SnapshotTests.swift          # Snapshot tests
└── AppView+ViewInspectorTests.swift     # ViewInspector tests
```

### Writing Tests

**Naming**: `test_<functionName>_<behaviorDescription>`

**Ordering**: Group by function name (alphabetical), then logical flow within group (success → failure → edge cases).

**Processor Test Template**:
```swift
class ExampleProcessorTests: BitwardenTestCase {
    var subject: ExampleProcessor!
    var coordinator: MockCoordinator<ExampleRoute, Void>!
    var exampleRepository: MockExampleRepository!

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        exampleRepository = MockExampleRepository()
        subject = ExampleProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(exampleRepository: exampleRepository),
            state: ExampleState()
        )
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
        coordinator = nil
        exampleRepository = nil
    }

    func test_perform_loadData_success_updatesState() async {
        exampleRepository.loadDataResult = .success("Test Data")
        await subject.perform(.loadData)
        XCTAssertEqual(subject.state.data, "Test Data")
    }

    func test_receive_nextAction_navigates() {
        subject.receive(.next)
        XCTAssertEqual(coordinator.routes.last, .nextExample)
    }
}
```

**Snapshot Test Template** (required modes: light, dark, large dynamic type):
```swift
class ExampleView_SnapshotTests: BitwardenTestCase {
    func test_snapshot_lightMode() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_darkMode() {
        assertSnapshot(of: subject, as: .defaultPortraitDark)
    }

    func test_snapshot_largeDynamicType() {
        assertSnapshot(of: subject, as: .defaultPortraitAX5)
    }
}
```

**Decision Matrix**:

| Component | Unit Tests | ViewInspector | Snapshots |
|-----------|-----------|---------------|-----------|
| Processor | Required | N/A | N/A |
| Service | Required | N/A | N/A |
| Repository | Required | N/A | N/A |
| Coordinator | Required | N/A | N/A |
| Model | If logic | N/A | N/A |
| View | N/A | Required | Required |

### Running Tests

```bash
# Unit tests (any simulator)
xcodebuild test -workspace Bitwarden.xcworkspace -scheme Bitwarden \
  -testPlan Bitwarden-Unit \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Snapshot tests (MUST match exact simulator)
xcodebuild test -workspace Bitwarden.xcworkspace -scheme Bitwarden \
  -testPlan Bitwarden-Snapshot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.0.1'

# Record new snapshots
RECORD_MODE=1 xcodebuild test -testPlan Bitwarden-Snapshot ...

# Authenticator tests
xcodebuild test -workspace Authenticator.xcworkspace -scheme Authenticator \
  -testPlan Authenticator-Unit \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Specific test
xcodebuild test -workspace Bitwarden.xcworkspace -scheme Bitwarden \
  -only-testing:BitwardenShared-Tests/ExampleProcessorTests/test_receive_action_updatesState
```

### Test Environment

- **Simulator**: Snapshot tests require a specific simulator name and iOS version (see `.test-simulator-device-name`, `.test-simulator-ios-version`)
- **Mock generation**: `// sourcery: AutoMockable` annotation on protocols → mocks generated in `*/Sourcery/Generated/AutoMockable.generated.swift`
- **ServiceContainer.withMocks()**: Convenience method in `ServiceContainer+Mocks.swift` providing all mock dependencies with sensible defaults
- **Test base class**: `BitwardenTestCase` (extends XCTest)
- **Test plans** in `TestPlans/`: `*-Default` (all), `*-Unit`, `*-Snapshot`, `*-ViewInspector`

---

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
- Import `BitwardenSdk` for SDK types, `BitwardenKit` for shared utilities

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

---

## Anti-Patterns

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

---

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
1. Verify simulator matches `.test-simulator-device-name` (iPhone 17 Pro) and `.test-simulator-ios-version` (26.0.1)
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
- **Diagnostic runes**: Check Xcode console for SDK errors (prefix: `BitwardenSdk`)
- **Network debugging**: Networking layer in `Networking/` Swift package — set breakpoints in `APIService` implementations
- **State debugging**: Add `print(subject.state)` in processor tests to inspect state changes

---

## References

### Critical Resources
- `Docs/Architecture.md` — Architecture patterns and principles (authoritative)
- `Docs/Testing.md` — Testing guidelines and component-specific strategies (authoritative)
- https://contributing.bitwarden.com/contributing/code-style/swift — Code style guidelines

**Do not duplicate information from these files — reference them instead.**

### Internal Documentation
- [Architectural Decision Records (ADRs)](https://contributing.bitwarden.com/architecture/adr/)
- [Contributing Guidelines](https://contributing.bitwarden.com/contributing/)
- [Accessibility](https://contributing.bitwarden.com/contributing/accessibility/)
- [Setup Guide](https://contributing.bitwarden.com/getting-started/mobile/ios/)

### Security Documentation
- [Security Whitepaper](https://bitwarden.com/help/bitwarden-security-white-paper/)
- [Security Definitions](https://contributing.bitwarden.com/architecture/security/definitions)

### Key Libraries
- [Bitwarden SDK](https://github.com/bitwarden/sdk-internal) — Rust-based cryptographic operations
- [ViewInspector](https://github.com/nalexn/ViewInspector) — SwiftUI view testing
- [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) — Visual regression testing
- [Sourcery](https://github.com/krzysztofzablocki/Sourcery) — Code generation for mocks
