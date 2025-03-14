import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - AnyCoordinatorTests

class AnyCoordinatorTests: BitwardenTestCase {
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

    /// `showErrorAlert(error:services:)` calls the `showErrorAlert()` method on the wrapped
    /// coordinator.
    @MainActor
    func test_showErrorAlert() async {
        let error = BitwardenTestError.example
        await subject.showErrorAlert(error: error, services: ServiceContainer.withMocks())
        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [error])
    }

    /// `showErrorAlert(error:services:tryAgain:)` calls the `showErrorAlert()` method on the
    /// wrapped coordinator.
    @MainActor
    func test_showErrorAlert_withTryAgain() async {
        let error = BitwardenTestError.example
        var tryAgainCalled = false
        await subject.showErrorAlert(error: error, services: ServiceContainer.withMocks()) {
            tryAgainCalled = true
        }
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
