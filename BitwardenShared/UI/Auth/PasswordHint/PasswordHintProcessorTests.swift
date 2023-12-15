import XCTest

@testable import BitwardenShared

// MARK: - PasswordHintProcessorTests

class PasswordHintProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute>!
    var subject: PasswordHintProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        let state = PasswordHintState()
        subject = PasswordHintProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: state
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform()` with `.submitPressed` submits the request for the master password hint.
    func test_perform_submitPressed() async throws {
        await subject.perform(.submitPressed)

        // TODO: BIT-733 Assert password hint service calls

        coordinator.loadingOverlaysShown = [LoadingOverlayState(title: Localizations.submitting)]
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, "")
        XCTAssertEqual(alert.message, Localizations.passwordHintAlert)
        XCTAssertEqual(alert.alertActions.count, 1)

        try await alert.tapAction(title: Localizations.ok)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive()` with `.dismissPressed` navigates to the `.dismiss` route.
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive()` with `.emailAddressChanged` and an empty value updates the state to reflect the
    /// changes.
    func test_receive_emailAddressChanged_withoutValue() {
        subject.state.emailAddress = "email@example.com"
        subject.receive(.emailAddressChanged(""))

        XCTAssertEqual(subject.state.emailAddress, "")
        XCTAssertFalse(subject.state.isSubmitButtonEnabled)
    }

    /// `receive()` with `.emailAddressChanged` and a value updates the state to reflect the
    /// changes.
    func test_receive_emailAddressChanged_withValue() {
        subject.state.emailAddress = ""
        subject.receive(.emailAddressChanged("email@example.com"))

        XCTAssertEqual(subject.state.emailAddress, "email@example.com")
        XCTAssertTrue(subject.state.isSubmitButtonEnabled)
    }
}
