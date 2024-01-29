import XCTest

@testable import BitwardenShared

class PendingRequestsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authService: MockAuthService!
    var coordinator: MockCoordinator<SettingsRoute>!
    var errorReporter: MockErrorReporter!
    var subject: PendingRequestsProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authService = MockAuthService()
        coordinator = MockCoordinator<SettingsRoute>()
        errorReporter = MockErrorReporter()

        subject = PendingRequestsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authService: authService,
                errorReporter: errorReporter
            ),
            state: PendingRequestsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        authService = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `loginRequestAnswered(approved:)` shows the toast and reloads the data.
    func test_loginRequestAnswered() {
        let task = Task {
            subject.loginRequestAnswered(approved: true)
        }

        waitFor(authService.getPendingLoginRequestCalled)
        task.cancel()
        XCTAssertEqual(subject.state.toast?.text, Localizations.loginApproved)
    }

    /// `perform(_:)` with `.loadData` loads the pending requests for the view.
    func test_perform_loadData() async {
        authService.getPendingLoginRequestResult = .success([.fixture()])

        await subject.perform(.loadData)

        XCTAssertTrue(authService.getPendingLoginRequestCalled)
        XCTAssertEqual(subject.state.loadingState, .data([.fixture()]))
    }

    /// `perform(_:)` with `.loadData` handles any errors from loading the data.
    func test_perform_loadData_error() async {
        authService.getPendingLoginRequestResult = .failure(BitwardenTestError.example)

        await subject.perform(.loadData)

        XCTAssertTrue(authService.getPendingLoginRequestCalled)
        XCTAssertEqual(subject.state.loadingState, .data([]))
        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `.receive(_:)` with `.declineAllRequestsTapped` shows the confirmation alert
    /// and declines all the requests.
    func test_receive_declineAllRequestsTapped() async throws {
        subject.state.loadingState = .data([.fixture()])

        subject.receive(.declineAllRequestsTapped)

        // Confirm on the alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.last)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertTrue(authService.getPendingLoginRequestCalled)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.loading)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
    }

    /// `.receive(_:)` with `.declineAllRequestsTapped` shows the confirmation alert
    /// and handles any errors from declining all the requests.
    func test_receive_declineAllRequestsTapped_error() async throws {
        subject.state.loadingState = .data([.fixture()])
        authService.denyAllLoginRequestsResult = .failure(BitwardenTestError.example)

        subject.receive(.declineAllRequestsTapped)

        // Confirm on the alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.last)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.loading)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `receive(_:)` with `.dismiss` dismisses the view
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.requestTapped(_)` shows the login request view.
    func test_receive_requestTapped() {
        subject.receive(.requestTapped(.fixture()))
        XCTAssertEqual(coordinator.routes.last, .loginRequest(.fixture()))
        XCTAssertNotNil(coordinator.contexts.last as? PendingRequestsProcessor)
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }
}
