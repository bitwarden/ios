import XCTest

@testable import AuthenticatorShared

// MARK: - AppCoordinatorTests

@MainActor
class AppCoordinatorTests: AuthenticatorTestCase {
    // MARK: Properties

    var module: MockAppModule!
    var rootNavigator: MockRootNavigator!
    var services: Services!
    var subject: AppCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        module = MockAppModule()
        rootNavigator = MockRootNavigator()
        services = ServiceContainer.withMocks()

        subject = AppCoordinator(
            appContext: .mainApp,
            module: module,
            rootNavigator: rootNavigator,
            services: services
        )
    }

    override func tearDown() {
        super.tearDown()
        module = nil
        rootNavigator = nil
        services = nil
        subject = nil
    }
}
