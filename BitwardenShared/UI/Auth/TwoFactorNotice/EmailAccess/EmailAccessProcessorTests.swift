import XCTest

@testable import BitwardenShared

// MARK: - EmailAccessProcessorTests

class EmailAccessProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<TwoFactorNoticeRoute, Void>!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: EmailAccessProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        let services = ServiceContainer.withMocks(
            errorReporter: errorReporter,
            stateService: stateService
        )

        subject = EmailAccessProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: EmailAccessState(
                allowDelay: true,
                emailAddress: "person@example.com"
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `.perform(_:)` with `.continueTapped` navigates to set up two factor
    /// when the user does not indicate they can access their email
    @MainActor
    func test_perform_continueTapped_canAccessEmail_false() async {
        subject.state.allowDelay = false
        subject.state.canAccessEmail = false
        await subject.perform(.continueTapped)
        XCTAssertEqual(coordinator.routes.last, .setUpTwoFactor(allowDelay: false, emailAddress: "person@example.com"))
    }

    /// `.perform(_:)` with `.continueTapped` updates the state and navigates to dismiss
    /// when the user indicates they can access their email
    /// and delay is not allowed
    @MainActor
    func test_perform_continueTapped_canAccessEmail_true_allowDelay_false() async {
        let account = Account.fixture()
        stateService.activeAccount = account
        subject.state.allowDelay = false
        subject.state.canAccessEmail = true
        await subject.perform(.continueTapped)
        XCTAssertEqual(
            stateService.twoFactorNoticeDisplayState["1"],
            .canAccessEmailPermanent
        )
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `.perform(_:)` with `.continueTapped` updates the state and navigates to dismiss
    /// when the user indicates they can access their email
    /// and delay is allowed
    @MainActor
    func test_perform_continueTapped_canAccessEmail_true_allowDelay_true() async {
        let account = Account.fixture()
        stateService.activeAccount = account
        subject.state.allowDelay = true
        subject.state.canAccessEmail = true
        await subject.perform(.continueTapped)
        XCTAssertEqual(
            stateService.twoFactorNoticeDisplayState["1"],
            .canAccessEmail
        )
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `.perform(_:)` with `.continueTapped` handles errors
    @MainActor
    func test_perform_continueTapped_error() async {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.setTwoFactorNoticeDisplayStateError = BitwardenTestError.example
        subject.state.allowDelay = false
        subject.state.canAccessEmail = true
        await subject.perform(.continueTapped)
        XCTAssertEqual(
            errorReporter.errors.last as? BitwardenTestError,
            BitwardenTestError.example
        )
    }

    /// `.receive(_:)` with `.canAccessEmailChanged` updates the state
    @MainActor
    func test_receive_canAccessEmailChanged() {
        subject.receive(.canAccessEmailChanged(true))
        XCTAssertTrue(subject.state.canAccessEmail)
        subject.receive(.canAccessEmailChanged(false))
        XCTAssertFalse(subject.state.canAccessEmail)
    }

    /// `receive(_:)` with `.clearURL` clears the URL in the state.
    @MainActor
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `receive(_:)` with `.learnMoreTapped` sends the user to the
    /// new device notice help site.
    @MainActor
    func test_receive_learnMoreTapped() {
        subject.receive(.learnMoreTapped)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.newDeviceVerification)
    }
}
