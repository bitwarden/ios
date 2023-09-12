import XCTest

@testable import BitwardenShared

// MARK: - AppCoordinatorTests

@MainActor
class AppCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var module: MockAppModule!
    var navigator: MockRootNavigator!
    var subject: AppCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        module = MockAppModule()
        navigator = MockRootNavigator()
        subject = AppCoordinator(
            module: module,
            navigator: navigator
        )
    }

    override func tearDown() {
        super.tearDown()
        module = nil
        navigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.onboarding` starts the auth coordinator and navigates to the proper auth route.
    func test_navigateTo_auth() throws {
        subject.navigate(to: .auth(.landing))

        XCTAssertTrue(module.authCoordinator.isStarted)
        XCTAssertEqual(module.authCoordinator.routes, [.landing])
    }

    /// `navigate(to:)` with `.auth(.landing)` twice uses the existing coordinator, rather than creating a new one.
    func test_navigateTo_authTwice() {
        subject.navigate(to: .auth(.landing))
        subject.navigate(to: .auth(.landing))

        XCTAssertEqual(module.authCoordinator.routes, [.landing, .landing])
    }

    /// `start()` initializes the interface correctly.
    func test_start() {
        subject.start()

        XCTAssertTrue(module.authCoordinator.isStarted)
    }

    /// `navigate(to:)` with `.auth(.landing)` presents the correct navigator.
    func test_navigateTo_onboarding() throws {
        subject.navigate(to: .auth(.landing))
        XCTAssertEqual(module.authCoordinator.routes, [.landing])
    }
}
