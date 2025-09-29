import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared

class LoginRequestProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authService: MockAuthService!
    var coordinator: MockCoordinator<LoginRequestRoute, Void>!
    var delegate: MockLoginRequestDelegate!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: LoginRequestProcessor!

    // MARK: Set Up & Tear Down

    override func setUp() {
        super.setUp()

        authService = MockAuthService()
        coordinator = MockCoordinator<LoginRequestRoute, Void>()
        delegate = MockLoginRequestDelegate()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        subject = LoginRequestProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                authService: authService,
                errorReporter: errorReporter,
                stateService: stateService
            ),
            state: LoginRequestState(request: .fixture())
        )
    }

    override func tearDown() {
        super.tearDown()

        authService = nil
        coordinator = nil
        delegate = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `.perform(_:)` with `.answerRequest` answers the request.
    @MainActor
    func test_perform_answerRequest() async {
        authService.getPendingLoginRequestResult = .success([.fixture()])

        await subject.perform(.answerRequest(approve: true))

        XCTAssertEqual(authService.getPendingLoginRequestId, "1")
        XCTAssertTrue(authService.answerLoginRequestApprove == true)
        XCTAssertEqual(authService.answerLoginRequestRequest, .fixture())
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.loading)
        guard case .dismiss = coordinator.routes.last else {
            return XCTFail("View not dismissed")
        }
    }

    /// `.perform(_:)` with `.answerRequest` handles an errors
    @MainActor
    func test_perform_answerRequest_error() async {
        authService.answerLoginRequestResult = .failure(BitwardenTestError.example)

        await subject.perform(.answerRequest(approve: true))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.loading)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `.perform(_:)` with `.loadData` loads the user's email address.
    @MainActor
    func test_perform_loadData() async {
        stateService.activeAccount = .fixture()
        await subject.perform(.loadData)
        XCTAssertEqual(subject.state.email, Account.fixture().profile.email)
    }

    /// `.perform(_:)` with `.loadData` handles any errors.
    func test_perform_loadData_error() async {
        await subject.perform(.loadData)
        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, .noActiveAccount)
    }

    /// `.perform(_:)` with `.reloadData` shows an alert for an answered request.
    @MainActor
    func test_perform_reloadData_answered() async throws {
        authService.getPendingLoginRequestResult = .success([
            .fixture(
                creationDate: .distantFuture,
                requestApproved: true,
                responseDate: Date()
            ),
        ])
        await subject.perform(.reloadData)
        XCTAssertEqual(coordinator.alertShown.last?.title, Localizations.thisRequestIsNoLongerValid)

        let okAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await okAction.handler?(okAction, [])
        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    /// `.perform(_:)` with `.reloadData` handles any errors.
    func test_perform_reloadData_error() async {
        authService.getPendingLoginRequestResult = .failure(BitwardenTestError.example)
        await subject.perform(.reloadData)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `.perform(_:)` with `.reloadData` shows an alert for an expired request.
    @MainActor
    func test_perform_reloadData_expired() async throws {
        authService.getPendingLoginRequestResult = .success([.fixture(creationDate: .distantPast)])
        await subject.perform(.reloadData)
        XCTAssertEqual(coordinator.alertShown.last?.title, Localizations.loginRequestHasAlreadyExpired)

        let okAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await okAction.handler?(okAction, [])
        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    /// `.receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }
}

// MARK: - MockLoginRequestDelegate

class MockLoginRequestDelegate: LoginRequestDelegate {
    var loginRequestAnsweredApproved: Bool?

    func loginRequestAnswered(approved: Bool) {
        loginRequestAnsweredApproved = approved
    }
}
