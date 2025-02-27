import XCTest

@testable import AuthenticatorShared

// MARK: - AnyCoordinatorTests

@MainActor
class AnyCoordinatorTests: AuthenticatorTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AppRoute, AppEvent>!
    var subject: AnyCoordinator<AppRoute, AppEvent>!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator<AppRoute, AppEvent>()
        subject = AnyCoordinator(coordinator)
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `start()` calls the `start()` method on the wrapped coordinator.
    func test_start() {
        subject.start()
        XCTAssertTrue(coordinator.isStarted)
    }

    /// `navigate(to:context:)` calls the `navigate(to:context:)` method on the wrapped coordinator.
    func test_navigate_onboarding() {
        subject.navigate(to: .tab(.itemList(.list)), context: "🤖" as NSString)
        XCTAssertEqual(coordinator.contexts as? [NSString], ["🤖" as NSString])
        XCTAssertEqual(coordinator.routes, [.tab(.itemList(.list))])
    }
}
