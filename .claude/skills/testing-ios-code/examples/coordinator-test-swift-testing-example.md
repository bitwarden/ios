# Coordinator Test Example (Swift Testing)

Based on: `AuthenticatorShared/UI/Platform/Application/AppCoordinatorTests.swift`

```swift
import BitwardenKit
import BitwardenKitMocks
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - FeatureCoordinatorTests

@MainActor
struct FeatureCoordinatorTests {
    // MARK: Properties

    let module: MockAppModule
    let stackNavigator: MockStackNavigator
    let subject: FeatureCoordinator

    // MARK: Initialization

    init() {
        module = MockAppModule()
        stackNavigator = MockStackNavigator()
        subject = FeatureCoordinator(
            module: module,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator,
        )
    }

    // MARK: Tests

    /// `navigate(to: .someScreen)` pushes the correct view.
    @Test
    func navigate_someScreen_pushesView() throws {
        subject.navigate(to: .someScreen)

        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .pushed)
        #expect(action.view is SomeView)
    }

    /// `navigate(to: .dismiss)` dismisses the current screen.
    @Test
    func navigate_dismiss_dismisses() {
        subject.navigate(to: .dismiss)

        #expect(stackNavigator.actions.last?.type == .dismissed)
    }

    /// `navigate(to: .childFlow)` starts the child coordinator.
    @Test
    func navigate_childFlow_startsChildCoordinator() {
        subject.navigate(to: .childFlow)

        #expect(module.childCoordinator.isStarted == true)
        #expect(module.childCoordinator.routes.last == .initialRoute)
    }
}
```

## Key Patterns

- `struct` with `init()` — fresh instance per test, no teardown
- `try #require()` — replaces `XCTUnwrap`; throws a test failure if nil
- `#expect(action.view is SomeView)` — type checking with `#expect`
- `MockStackNavigator` — same navigation capture as XCTest version
- `stackNavigator.actions.last?.type` — `.pushed`, `.presented`, `.dismissed`
- `module.childCoordinator.isStarted` — verify child coordinator was started
