import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

// MARK: - AnyCoordinatorTests

class AnyCoordinatorTests: BitwardenTestCase {
    // MARK: Types

    enum TestAuthRoute: Equatable {
        case landing
    }

    enum TestEvent: Equatable {
        case didStart
    }

    enum TestRoute: Equatable {
        case auth(TestAuthRoute)
    }

    // MARK: Properties

    var coordinator: MockCoordinator<TestRoute, TestEvent>!
    var subject: AnyCoordinator<TestRoute, TestEvent>!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator<TestRoute, TestEvent>()
        subject = AnyCoordinator(coordinator)
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `showErrorAlert(error:)` calls the `showErrorAlert()` method on the wrapped
    /// coordinator.
    @MainActor
    func test_showErrorAlert() async {
        let error = BitwardenTestError.example
        await subject.showErrorAlert(error: error)
        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [error])
    }

    /// `showErrorAlert(error:tryAgain:)` calls the `showErrorAlert()` method on the wrapped
    /// coordinator.
    @MainActor
    func test_showErrorAlert_withTryAgain() async {
        let error = BitwardenTestError.example
        var tryAgainCalled = false
        await subject.showErrorAlert(error: error, tryAgain: {
            tryAgainCalled = true
        })
        XCTAssertEqual(coordinator.errorAlertsWithRetryShown.map(\.error) as? [BitwardenTestError], [error])

        let errorAlertWithRetry = coordinator.errorAlertsWithRetryShown[0]
        await errorAlertWithRetry.retry()
        XCTAssertTrue(tryAgainCalled)
    }

    /// `start()` calls the `start()` method on the wrapped coordinator.
    @MainActor
    func test_start() {
        subject.start()
        XCTAssertTrue(coordinator.isStarted)
    }

    /// `navigate(to:context:)` calls the `navigate(to:context:)` method on the wrapped coordinator.
    @MainActor
    func test_navigate_onboarding() {
        subject.navigate(to: .auth(.landing), context: "🤖" as NSString)
        XCTAssertEqual(coordinator.contexts as? [NSString], ["🤖" as NSString])
        XCTAssertEqual(coordinator.routes, [.auth(.landing)])
    }
}
