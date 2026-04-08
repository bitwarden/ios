# iOS Implementation Templates

Minimal copy-paste skeletons derived from actual codebase patterns.
See `Docs/Architecture.md` for full pattern documentation.

## New Feature File-Set

When adding a new screen, create these files (replace `<Feature>` throughout):

```
BitwardenShared/UI/<Domain>/<Feature>/
├── <Feature>Processor.swift
├── <Feature>State.swift
├── <Feature>Action.swift
├── <Feature>Effect.swift
└── <Feature>View.swift
```

Add a new case to the **parent** Coordinator's existing `Route` enum rather than creating a new `Route` file.

**When to create a new Coordinator:** Most screens do NOT need their own coordinator. A single coordinator typically manages an entire feature flow with many routes (e.g., `AuthCoordinator` handles ~30 screens). Only create a new child coordinator when the flow introduces a new navigation container (e.g., a new modal or tab) or becomes complex enough to warrant isolation. When in doubt, add a route to the parent coordinator.

---

## Coordinator Skeleton

Based on: `BitwardenShared/UI/Auth/AuthCoordinator.swift`

```swift
import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - <Feature>Coordinator

/// A coordinator that manages navigation in the <feature> flow.
///
final class <Feature>Coordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = Has<Service1>
        & Has<Service2>

    // MARK: Properties

    private let services: Services
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    init(services: Services, stackNavigator: StackNavigator) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: <Parent>Route, context: AnyObject?) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss()
        case .<featureRoute>:
            show<Feature>()
        }
    }

    func start() {}

    // MARK: Private

    private func show<Feature>() {
        let processor = <Feature>Processor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: <Feature>State(),
        )
        let store = Store(processor: processor)
        let view = <Feature>View(store: store)
        stackNavigator?.push(view)
    }
}
```

---

## Processor Skeleton

Based on: `BitwardenShared/UI/Auth/Landing/LandingProcessor.swift`

```swift
import BitwardenKit

// MARK: - <Feature>Processor

/// The processor used to manage state and handle actions for the <feature> screen.
///
class <Feature>Processor: StateProcessor<<Feature>State, <Feature>Action, <Feature>Effect> {
    // MARK: Types

    typealias Services = Has<Service1>
        & Has<Service2>

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<<Parent>Route, <Parent>Event>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    init(
        coordinator: AnyCoordinator<<Parent>Route, <Parent>Event>,
        services: Services,
        state: <Feature>State,
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: <Feature>Effect) async {
        switch effect {
        case .appeared:
            await loadData()
        }
    }

    override func receive(_ action: <Feature>Action) {
        switch action {
        case let .someValueChanged(newValue):
            state.someValue = newValue
        }
    }

    // MARK: Private

    private func loadData() async {
        do {
            // use services.<service>.<method>()
        } catch {
            coordinator.showErrorAlert(error: error)
        }
    }
}
```

---

## State / Action / Effect Skeletons

Based on: `BitwardenShared/UI/Auth/Landing/Landing{State,Action,Effect}.swift`

```swift
// MARK: - <Feature>State

/// An object that defines the current state of a `<Feature>View`.
///
struct <Feature>State: Equatable {
    // MARK: Properties

    var someValue: String = ""
}
```

```swift
// MARK: - <Feature>Action

/// Actions that can be processed by a `<Feature>Processor`.
///
enum <Feature>Action: Equatable {
    /// A value was changed by the user.
    case someValueChanged(String)
}
```

```swift
// MARK: - <Feature>Effect

/// Effects that can be processed by a `<Feature>Processor`.
///
enum <Feature>Effect: Equatable {
    /// The view appeared on screen.
    case appeared
}
```

---

## View Skeleton

Based on: `BitwardenShared/UI/Auth/Landing/LandingView.swift`

```swift
import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - <Feature>View

/// A view for <feature description>.
///
struct <Feature>View: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<<Feature>State, <Feature>Action, <Feature>Effect>

    // MARK: View

    var body: some View {
        content
            .task {
                await store.perform(.appeared)
            }
    }

    // MARK: Private Views

    private var content: some View {
        VStack {
            // Example: text field backed by store state
            BitwardenTextField(
                title: Localizations.someLabel,
                text: store.binding(
                    get: \.someValue,
                    send: <Feature>Action.someValueChanged,
                ),
            )
        }
        .navigationBarTitle(Localizations.featureTitle, displayMode: .inline)
    }
}
```

---

## Service Skeleton

Based on: `BitwardenShared/Core/Platform/Services/PasteboardService.swift`

```swift
import BitwardenKit

// MARK: - <Name>Service

// sourcery: AutoMockable
/// A protocol for a service that <description>.
///
protocol <Name>Service: AnyObject {
    /// Does something asynchronously.
    ///
    func doSomething() async throws
}

// MARK: - Default<Name>Service

/// A default implementation of `<Name>Service`.
///
class Default<Name>Service: <Name>Service {
    // MARK: Private Properties

    private let errorReporter: ErrorReporter

    // MARK: Initialization

    init(errorReporter: ErrorReporter) {
        self.errorReporter = errorReporter
    }

    // MARK: Methods

    func doSomething() async throws {
        // Implementation
    }
}

// MARK: - Has<Name>Service

/// A protocol for an object that provides a `<Name>Service`.
///
protocol Has<Name>Service {
    /// The service used for <description>.
    var <name>Service: <Name>Service { get }
}
```

---

## Repository Pattern

Repositories follow the same protocol + Default + Has* pattern as services, but operate on domain models and typically inject both a data store and a network client:

```swift
// sourcery: AutoMockable
protocol <Name>Repository: AnyObject {
    func fetchItems() async throws -> [<Model>]
}

class Default<Name>Repository: <Name>Repository {
    private let <name>DataStore: <Name>DataStore
    private let <name>APIService: <Name>APIService

    init(<name>DataStore: <Name>DataStore, <name>APIService: <Name>APIService) {
        self.<name>DataStore = <name>DataStore
        self.<name>APIService = <name>APIService
    }

    func fetchItems() async throws -> [<Model>] {
        // Implementation
    }
}

protocol Has<Name>Repository {
    var <name>Repository: <Name>Repository { get }
}
```
