import BitwardenKit
import XCTest

@testable import TestHarnessShared

/// Tests for `AppProcessor`.
///
class AppProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appModule: MockAppModule!
    var subject: AppProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        appModule = MockAppModule()
        let services = ServiceContainer()
        subject = AppProcessor(appModule: appModule, services: services)
    }

    override func tearDown() {
        super.tearDown()
        appModule = nil
        subject = nil
    }

    // MARK: Tests

    /// `start()` creates and starts the app coordinator.
    func test_start() async {
        let navigator = MockRootNavigator()
        await subject.start(navigator: navigator, window: nil)

        XCTAssertTrue(appModule.makeAppCoordinatorCalled)
        XCTAssertNotNil(subject.coordinator)
    }
}

/// A mock `AppModule` for testing.
///
@MainActor
class MockAppModule: AppModule {
    var makeAppCoordinatorCalled = false

    func makeAppCoordinator(navigator: RootNavigator) -> AnyCoordinator<AppRoute, AppEvent> {
        makeAppCoordinatorCalled = true
        return AppCoordinator(
            module: self,
            rootNavigator: navigator,
            services: ServiceContainer(),
        ).asAnyCoordinator()
    }
}

extension MockAppModule: RootModule {
    func makeRootCoordinator(stackNavigator: StackNavigator) -> AnyCoordinator<RootRoute, Void> {
        RootCoordinator(
            services: ServiceContainer(),
            stackNavigator: stackNavigator,
        ).asAnyCoordinator()
    }
}
