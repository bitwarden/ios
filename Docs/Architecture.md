# Architecture

- [Overview](#overview)
- [Core Layer](#core-layer)
  - [Models](#models)
  - [Data Stores](#data-stores)
  - [Services](#services)
  - [Repositories](#repositories)
- [UI Layer](#ui-layer)
  - [Coordinator](#coordinator)
  - [Processor](#processor)
  - [State](#state)
  - [View](#view)
  - [Actions and Effects](#actions-and-effects)
  - [Example](#example)

## Overview

The Bitwarden app is composed of the following targets:

- `Bitwarden`: The main iOS app. 
- `BitwardenActionExtension`: An [Action extension](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Action.html) that can be accessed via the system share sheet "Autofill with Bitwarden" option. 
- `BitwardenAutoFillExtension`: An AutoFill Credential Provider extension which allows Bitwarden to offer up credentials for [Password AutoFill](https://developer.apple.com/documentation/security/password_autofill/).
- `BitwardenShareExtension`: A [Share extension](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html) that allows creating text or file sends via the system share sheet. 
- `BitwardenWatchApp`: The companion watchOS app.

Additionally, the following top-level folders provide shared functionality between the targets:

- `BitwardenShared`: A framework that is shared between the app and extensions.
- `BitwardenWatchShared`: Models and encoding/decoding logic for communicating between the iOS and watchOS apps.
- `GlobalTestHelpers`: Shared functionality between the app's test targets. 
- `Networking`: A local Swift package that implements the app's networking layer on top of `URLSession`. 

Most of the app's functionality is implemented in the `BitwardenShared` target. The files within this target are split up between two top-level folders, `Core` and `UI`. Each of these folders is then subdivided into the following folders:

- `Auth`
- `Autofill`
- `Platform`
- `Tools`
- `Vault`

These folders align with the [CODEOWNERS](../.github/CODEOWNERS) file for the project; no additional direct subfolders of `Core` or `UI` should be added. While this top-level structure is deliberately inflexible, the folder structure within the subfolders are not specifically prescribed.

The responsibilities of the core layer are to manage the storage and retrieval of data from low-level sources (such as from the network, persistence, or Bitwarden SDK) and to expose them in a more ready-to-consume manner by the UI layer via "repository" and "service" classes. The UI layer is then responsible for any final processing of this data for display in the UI as well as receiving events from the UI and updating the tracked state accordingly.

## Core Layer

The core layer is where all the UI-independent data is stored and retrieved. It consists of both raw data sources as well as higher-level "repository" and "service" classes. 

### Models

The lowest level of the core layer are the data model objects. These are the raw sources of data that include data retrieved or sent via network requests, data persisted with [CoreData](https://developer.apple.com/documentation/coredata/), and data that is used to interact with the [Bitwarden SDK](https://github.com/bitwarden/sdk).

The models are roughly organized based on their use and type:

- `Domain`: Models that represent the main data types within the app.
- `Enum`: Enumeration model types.
- `Request`: Request models are data models used in the body of an API request.
- `Response`: Response models are typically the top-level data models that are decoded from an API response. These models may utilize domain and enum models that are shared between responses.

### Data Stores

Data stores are responsible for persisting data to Core Data or UserDefaults.

### Services

Services represent the middle layer of the core layer. While some services may depend on other services or lower-level data stores (e.g. [CipherService](../BitwardenShared/Core/Vault/Services/CipherService.swift)), others are wrappers around OS-level functionality (e.g. [NFCReaderService](../BitwardenShared/Core/Platform/Services/NFCReaderService.swift)). The commonality amongst the services is that they tend to have a single discrete responsibility. These classes may exist solely in the core layer for use inside a repository or another service, like [CipherService](../BitwardenShared/Core/Vault/Services/CipherService.swift), or may be exposed directly to the UI layer, like [NFCReaderService](../BitwardenShared/Core/Platform/Services/NFCReaderService.swift).

### Repositories

Repositories are at the outermost layer of the core layer. Repositories are usually composed of one or more services, and in rare cases other repositories. Repositories are meant to be exposed directly to the UI layer. They synthesize data from multiple sources and combine various asynchronous requests as necessary to expose data to the UI layer in a more appropriate form. These classes tend to have broad responsibilities that generally cover a major domain of the app, such as authentication ([AuthRepository](../BitwardenShared/Core/Auth/Repositories/AuthRepository.swift)) or vault access ([VaultRepository](../BitwardenShared/Core/Vault/Repositories/VaultRepository.swift)). 

## UI Layer

The UI layer utilizes a unidirectional data flow pattern that is based on coordinators and processors.

### Coordinator

Coordinators create processors and views to facilitate navigation between views or flows within the application. In general, a coordinator is responsible for managing navigation within a single container view controller (e.g. `UINavigationController`, `UITabBarController`).

Occasionally, a single coordinator can manage the navigation within an entire feature flow (e.g. [AuthCoordinator](../BitwardenShared/UI/Auth/AuthCoordinator.swift) handles the navigation between authentication views). Once a flow becomes complex enough, or the container view controller changes (e.g. a `UINavigationController` is presented which has its own set of flows), the coordinator can create and display a child coordinator. An example of this is how [VaultCoordinator](../BitwardenShared/UI/Vault/Vault/VaultCoordinator.swift) handles navigation within the vault tab and [VaultItemCoordinator](../BitwardenShared/UI/Vault/VaultItem/VaultItemCoordinator.swift) handles navigation for viewing, adding, or editing vault items in a presented `UINavigationController`.

Coordinators should remain free of business logic. Logic should be handled in the processor prior to navigation or in the new processor after navigation occurs. In rare cases where there is a lot of logic around what view should come next, a router can be implemented to work alongside the coordinator. An example of this is [AuthRouter](../BitwardenShared/UI/Auth/AuthRouter.swift), which makes decisions around which route should be navigated to next within the authentication flow.

### Processor

Processors manage the state and business logic for a view. Processors are the only location where state mutation occurs. Processors receive actions and effects from the view, performs any business logic and then updates the state. Whenever a processor updates its state, it automatically publishes the new state to the view.

If a change in state necessitates a navigation change, the processor requests that its coordinator handle the navigation to a new view.

### State

State represents the data and configuration needed to perform the processor's logic and render the UI for a feature. All information needed to configure the UI associated with the processor should be included in the state.

### View

A view renders the UI based on its state. The state within a view is managed by a [Store](../BitwardenShared/UI/Platform/Application/Utilities/Store.swift). The store is the connection between the processor and the view. Views never mutate state directly; instead, they send actions or perform effects via the store which are forwarded back to the processor. Views are updated by the store anytime the state changes.

### Actions and Effects

Actions are triggered by the view and represent interactions with the processor that could potentially cause an update to state or navigation. These will usually be sent because of some user interaction with the UI, such as a button being tapped or a text field's value changing. Actions are processed synchronously by the processor.

Effects are like actions, but usually represent side-effects where the processor needs to communicate with an external repository or service. Effects are asynchronous and may perform some work before updating the state, examples which include loading or subscribing to data for the view or making API requests. Long-running tasks such as subscribing to an [AsyncPublisher](https://developer.apple.com/documentation/combine/asyncpublisher) should use the [task](https://developer.apple.com/documentation/swiftui/view/task(priority:_:)) modifier on the view so that the task is cancelled if the view disappears before the task completes.

Actions and effects are implemented as enumerations so that adding a new action or effect ensures the processor is updated to handle the new case.

### Example

The following example demonstrates the above components in the architecture.

- The coordinator creates the processor and view and handles navigation within its navigator (in this case a [StackNavigator](../BitwardenShared/UI/Platform/Application/Utilities/StackNavigator.swift) which is implemented by a `UINavigationController`).
- The processor and view share:
    - State containing the properties that are used to configure the UI: `data` and `isToggleOn`.
    - Actions that are used by the processor to update the state (`updateToggle`) or trigger navigation (`nextExample`).
    - Effects that perform asynchronous work: `loadData` fetches some data to display from the repository.
- The view builds the UI based on the current state in the store and notifies the processor via actions or effects as interactions occur.
- The processor responds to actions by updating the state or triggering navigation via the coordinator. Effects are used to kick off asynchronous work.

<details>
<summary>Show example</summary>

```swift
final class ExampleCoordinator: Coordinator, HasStackNavigator {
    typealias Event = Void
    typealias Services = HasExampleRepository

    private let services: Services
    private(set) weak var stackNavigator: StackNavigator?

    init(services: Services, stackNavigator: StackNavigator?) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    func start() {}

    func navigate(to route: ExampleRoute, context: AnyObject?) {
        switch route {
        case .example:
            showExample()
        case .nextExample:
            // ...
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

struct ExampleState: Equatable {
    var data: String?
    var isToggleOn = false
}

enum ExampleAction: Equatable {
    case nextExample
    case updateToggle(Bool)
}

enum ExampleEffect: Equatable {
    case loadData
}

final class ExampleProcessor: StateProcessor<ExampleState, ExampleAction, ExampleEffect> {
    typealias Services = HasExampleRepository

    private var coordinator: any Coordinator<ExampleRoute, Void>
    private var services: Services

    init(coordinator: any Coordinator<ExampleRoute, Void>, services: Services, state: ExampleState) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    override func receive(_ action: ExampleAction) {
        switch action {
        case .nextExample:
            coordinator.navigate(to: .nextExample)
        case let .updateToggle(newValue):
            state.isToggleOn = newValue
        }
    }

    override func perform(_ effect: ExampleEffect) async {
        switch effect {
        case .loadData:
            await loadData()
        }
    }

    private func loadData() async {
        do {
            state.data = try await services.exampleRepository.loadData()
        } catch {
            // Handle errors.
        }
    }
}

struct ExampleView: View {
    @ObservedObject var store: Store<ExampleState, ExampleAction, ExampleEffect>

    var body: some View {
        VStack {
            if let data = store.state.data {
                Text(data)
            }

            Toggle(
                Localizations.toggleExample,
                isOn: store.binding(
                    get: \.isToggleOn,
                    send: ExampleAction.updateToggle
                )
            )

            Button(Localizations.next) {
                store.send(.nextExample)
            }
        }
        .task {
            await store.perform(.loadData)
        }
    }
}
```

</details>
