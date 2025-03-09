import TestHelpers
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
            state: SetUpTwoFactorState(allowDelay: true, emailAddress: "person@example.com")
        )

        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.lastSyncTimeByUserId["1"] = timeProvider.presentTime
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
        await subject.perform(.changeAccountEmailTapped)
        waitFor(!coordinator.alertShown.isEmpty)
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(subject.state.url, url)
        XCTAssertNil(stateService.lastSyncTimeByUserId["1"])
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
        await subject.perform(.turnOnTwoFactorTapped)
        waitFor(!coordinator.alertShown.isEmpty)
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(subject.state.url, url)
        XCTAssertNil(stateService.lastSyncTimeByUserId["1"])
    }
}
