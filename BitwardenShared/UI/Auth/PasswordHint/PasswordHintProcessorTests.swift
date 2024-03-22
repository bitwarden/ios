import XCTest

@testable import BitwardenShared

// MARK: - PasswordHintProcessorTests

class PasswordHintProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var httpClient: MockHTTPClient!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var subject: PasswordHintProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        httpClient = MockHTTPClient()
        let services = ServiceContainer.withMocks(httpClient: httpClient)
        let state = PasswordHintState()
        subject = PasswordHintProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: state
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        httpClient = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform()` with `.submitPressed` submits the request for the master password hint.
    func test_perform_submitPressed_success() async throws {
        subject.state.emailAddress = "email@example.com"
        httpClient.results = [.success(.success(statusCode: 200))]
        await subject.perform(.submitPressed)

        // TODO: BIT-733 Assert password hint service calls
        XCTAssertEqual(httpClient.requests.count, 1)
        let request = try XCTUnwrap(httpClient.requests.first)
        XCTAssertEqual(request.url, URL(string: "https://example.com/api/accounts/password-hint"))
        XCTAssertEqual(request.body, try PasswordHintRequestModel(email: "email@example.com").encode())

        coordinator.loadingOverlaysShown = [LoadingOverlayState(title: Localizations.submitting)]
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
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
