import XCTest

@testable import BitwardenShared

// MARK: - AnyCoordinatorTests

@MainActor
class AnyCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AppRoute>!
    var subject: AnyCoordinator<AppRoute>!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator<AppRoute>()
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
        subject.navigate(to: .auth(.landing), context: "🤖" as NSString)
        XCTAssertEqual(coordinator.contexts as? [NSString], ["🤖" as NSString])
        XCTAssertEqual(coordinator.routes, [.auth(.landing)])
    }
}
