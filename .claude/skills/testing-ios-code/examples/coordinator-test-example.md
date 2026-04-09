# Coordinator Test Example

Based on: `BitwardenShared/UI/Auth/AuthCoordinatorTests.swift`

```swift
import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - FeatureCoordinatorTests

class FeatureCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var module: MockAppModule!
    var services: MockServiceContainer!
    var stackNavigator: MockStackNavigator!
    var subject: FeatureCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        module = MockAppModule()
        services = ServiceContainer.withMocks()
        stackNavigator = MockStackNavigator()
        subject = FeatureCoordinator(
            module: module,
            services: services,
            stackNavigator: stackNavigator,
        )
    }

    override func tearDown() {
        super.tearDown()

        module = nil
        services = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to: .someScreen)` pushes the correct view.
    @MainActor
    func test_navigate_someScreen_pushesView() throws {
        subject.navigate(to: .someScreen)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is SomeView)
    }

    /// `navigate(to: .dismiss)` dismisses the current screen.
    @MainActor
    func test_navigate_dismiss_dismisses() {
        subject.navigate(to: .dismiss)

        XCTAssertEqual(stackNavigator.actions.last?.type, .dismissed)
    }

    /// `navigate(to: .childFlow)` starts the child coordinator.
    @MainActor
    func test_navigate_childFlow_startsChildCoordinator() throws {
        subject.navigate(to: .childFlow)

        XCTAssertTrue(module.childCoordinator.isStarted)
        XCTAssertEqual(module.childCoordinator.routes.last, .initialRoute)
    }
}
```

## Key Patterns

- `MockStackNavigator` — captures navigation actions
- `stackNavigator.actions.last?.type` — `.pushed`, `.presented`, `.dismissed`, `.dismissedWithCompletionHandler`
- `action.view is SomeView` — verify the correct view was pushed
- `XCTUnwrap` — safely unwrap optional `actions.last` before asserting on it
- `module.childCoordinator.isStarted` — verify child coordinator was started
