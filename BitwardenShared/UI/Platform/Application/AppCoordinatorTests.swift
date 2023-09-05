import XCTest

@testable import BitwardenShared

// MARK: - AppCoordinatorTests

@MainActor
class AppCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var navigator: MockRootNavigator!
    var subject: AppCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        navigator = MockRootNavigator()
        subject = AppCoordinator(navigator: navigator)
    }

    override func tearDown() {
        super.tearDown()
        navigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `start()` initializes the UI correctly.
    func test_start() {
        subject.start()

        // Placeholder assertion until functionality is implemented in BIT-155
        XCTAssertTrue(navigator.navigatorShown is StackNavigator)
    }

    /// `navigate(to:)` with `.onboarding` presents the correct navigator.
    func test_navigateTo_onboarding() throws {
        subject.navigate(to: .onboarding)

        // Placeholder assertion until functionality is implemented in BIT-155
        XCTAssertTrue(navigator.navigatorShown is StackNavigator)
    }
}
