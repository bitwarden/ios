import XCTest

@testable import BitwardenShared

// MARK: - SetUpTwoFactorProcessorTests

class SetUpTwoFactorProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<TwoFactorNoticeRoute, Void>!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: SetUpTwoFactorProcessor!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(Date()))

        let services = ServiceContainer.withMocks(
            environmentService: environmentService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider
        )

        subject = SetUpTwoFactorProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: SetUpTwoFactorState(allowDelay: true)
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        environmentService = nil
        errorReporter = nil
        stateService = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// `.perform(_:)` with `.remindMeLaterTapped` saves the current time to disk
    /// then dismisses
    @MainActor
    func test_perform_remindMeLaterTapped() async {
        let account = Account.fixture()
        stateService.activeAccount = account
        await subject.perform(.remindMeLaterTapped)
        XCTAssertEqual(
            stateService.twoFactorNoticeDisplayState["1"],
            .seen(timeProvider.presentTime)
        )
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `.perform(_:)` with `.remindMeLaterTapped` handles errors
    @MainActor
    func test_perform_remindMeLaterTapped_error() async {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.setTwoFactorNoticeDisplayStateError = BitwardenTestError.example
        await subject.perform(.remindMeLaterTapped)
        XCTAssertEqual(
            errorReporter.errors.last as? BitwardenTestError,
            BitwardenTestError.example
        )
    }

    /// `receive(_:)` with `.changeAccountEmail` shows an alert;
    /// and when continue is tapped, the user is sent to the set up two factor site.
    @MainActor
    func test_receive_changeAccountEmailTapped() async throws {
        let url = URL("https://www.example.com")!
        environmentService.changeEmailURL = url
        subject.receive(.changeAccountEmailTapped)
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(subject.state.url, url)
    }

    /// `receive(_:)` with `.clearURL` clears the URL in the state.
    @MainActor
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `receive(_:)` with `.turnOnTwoFactorTapped` shows an alert;
    /// and when continue is tapped, the user is sent to the set up two factor site.
    @MainActor
    func test_receive_turnOnTwoFactorTapped() async throws {
        let url = URL("https://www.example.com")!
        environmentService.setUpTwoFactorURL = url
        subject.receive(.turnOnTwoFactorTapped)
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(subject.state.url, url)
    }

//    /// `.perform` with `.continueTapped` navigates to set up two factor
//    /// when the user does not indicate they can access their email
//    @MainActor
//    func test_perform_continueTapped_canAccessEmail_false() async {
//        subject.state.allowDelay = false
//        subject.state.canAccessEmail = false
//        await subject.perform(.continueTapped)
//        XCTAssertEqual(coordinator.routes.last, .setUpTwoFactor(allowDelay: false))
//    }
//
//    /// `.perform` with `.continueTapped` updates the state and navigates to dismiss
//    /// when the user indicates they can access their email
//    /// and delay is not allowed
//    @MainActor
//    func test_perform_continueTapped_canAccessEmail_true_allowDelay_false() async {
//        let account = Account.fixture()
//        stateService.activeAccount = account
//        subject.state.allowDelay = false
//        subject.state.canAccessEmail = true
//        await subject.perform(.continueTapped)
//        XCTAssertEqual(
//            stateService.twoFactorNoticeDisplayState["1"],
//            .canAccessEmailPermanent
//        )
//        XCTAssertEqual(coordinator.routes.last, .dismiss)
//    }
//
//    /// `.perform` with `.continueTapped` updates the state and navigates to dismiss
//    /// when the user indicates they can access their email
//    /// and delay is allowed
//    @MainActor
//    func test_perform_continueTapped_canAccessEmail_true_allowDelay_true() async {
//        let account = Account.fixture()
//        stateService.activeAccount = account
//        subject.state.allowDelay = true
//        subject.state.canAccessEmail = true
//        await subject.perform(.continueTapped)
//        XCTAssertEqual(
//            stateService.twoFactorNoticeDisplayState["1"],
//            .canAccessEmail
//        )
//        XCTAssertEqual(coordinator.routes.last, .dismiss)
//    }
//
//    /// `.perform` with `.continueTapped` handles errors
//    @MainActor
//    func test_perform_continueTapped_error() async {
//        let account = Account.fixture()
//        stateService.activeAccount = account
//        stateService.setTwoFactorNoticeDisplayStateError = BitwardenTestError.example
//        subject.state.allowDelay = false
//        subject.state.canAccessEmail = true
//        await subject.perform(.continueTapped)
//        XCTAssertEqual(
//            errorReporter.errors.last as? BitwardenTestError,
//            BitwardenTestError.example
//        )
//    }
//
//    /// `.receive()` with `.canAccessEmailChanged` updates the state
//    @MainActor
//    func test_receive_canAccessEmailChanged() {
//        subject.receive(.canAccessEmailChanged(true))
//        XCTAssertTrue(subject.state.canAccessEmail)
//        subject.receive(.canAccessEmailChanged(false))
//        XCTAssertFalse(subject.state.canAccessEmail)
//    }
}

