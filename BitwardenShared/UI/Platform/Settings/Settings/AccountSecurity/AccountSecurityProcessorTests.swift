import XCTest

@testable import BitwardenShared

class AccountSecurityProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var errorReporter: MockErrorReporter!
    var settingsRepository: MockSettingsRepository!
    var stateService: MockStateService!
    var twoStepLoginService: MockTwoStepLoginService!
    var subject: AccountSecurityProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        errorReporter = MockErrorReporter()
        settingsRepository = MockSettingsRepository()
        stateService = MockStateService()
        twoStepLoginService = MockTwoStepLoginService()

        subject = AccountSecurityProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                settingsRepository: settingsRepository,
                stateService: stateService,
                twoStepLoginService: twoStepLoginService
            ),
            state: AccountSecurityState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        settingsRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.lockVault` locks the user's vault.
    func test_perform_lockVault() async {
        let account: Account = .fixtureAccountLogin()
        stateService.activeAccount = account

        await subject.perform(.lockVault)

        XCTAssertEqual(settingsRepository.lockVaultCalls, [account.profile.userId])
        XCTAssertEqual(coordinator.routes.last, .lockVault(account: account))
    }

    /// `perform(_:)` with `.lockVault` fails, locks the vault and navigates to the landing screen.
    func test_perform_lockVault_failure() async {
        await subject.perform(.lockVault)

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [StateServiceError.noActiveAccount])
        XCTAssertEqual(coordinator.routes.last, .logout)
    }

    /// `receive(_:)` with `.twoStepLoginPressed` clears the two step login URL.
    func test_receive_clearTwoStepLoginUrl() async throws {
        subject.receive(.twoStepLoginPressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()

        // Tapping yes navigates the user to the web app.
        try await alert.tapAction(title: Localizations.yes)
        XCTAssertNotNil(subject.state.twoStepLoginUrl)

        subject.receive(.clearTwoStepLoginUrl)
        XCTAssertNil(subject.state.twoStepLoginUrl)
    }

    /// `receive(_:)` with `.deleteAccountPressed` shows the `DeleteAccountView`.
    func test_receive_deleteAccountPressed() throws {
        subject.receive(.deleteAccountPressed)

        XCTAssertEqual(coordinator.routes.last, .deleteAccount)
    }

    /// `receive(_:)` with `.logout` presents a logout confirmation alert.
    func test_receive_logout() async throws {
        subject.receive(.logout)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.logOut)
        XCTAssertEqual(alert.message, Localizations.logoutConfirmation)
        XCTAssertEqual(alert.preferredStyle, .alert)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        settingsRepository.logoutResult = .success(())
        // Tapping yes logs the user out.
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(coordinator.routes.last, .logout)
    }

    /// `receive(_:)` with `.logout` presents a logout confirmation alert.
    func test_receive_logout_error() async throws {
        subject.receive(.logout)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.logOut)
        XCTAssertEqual(alert.message, Localizations.logoutConfirmation)
        XCTAssertEqual(alert.preferredStyle, .alert)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        // Tapping yes relays any errors to the error reporter.
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(
            errorReporter.errors as? [StateServiceError],
            [StateServiceError.noActiveAccount]
        )
    }

    /// `receive(_:)` with `sessionTimeoutActionChanged(:)` presents an alert if `logout` was selected.
    /// It then updates the state if `Yes` was tapped on the alert, confirming the user's decision.
    func test_receive_sessionTimeoutActionChanged_logout() async throws {
        XCTAssertEqual(subject.state.sessionTimeoutAction, .lock)
        subject.receive(.sessionTimeoutActionChanged(.logout))

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.warning)
        XCTAssertEqual(alert.message, Localizations.vaultTimeoutLogOutConfirmation)
        XCTAssertEqual(alert.alertActions.count, 2)

        XCTAssertEqual(alert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[0].style, .default)
        XCTAssertNotNil(alert.alertActions[0].handler)

        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)
        XCTAssertEqual(alert.alertActions[1].style, .cancel)
        XCTAssertNil(alert.alertActions[1].handler)

        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)
    }

    /// `receive(_:)` with `sessionTimeoutActionChanged(:)` updates the state when `lock` was selected.
    func test_receive_sessionTimeoutActionChanged_lock() async throws {
        XCTAssertEqual(subject.state.sessionTimeoutAction, .lock)
        subject.receive(.sessionTimeoutActionChanged(.logout))

        let alert = try coordinator.unwrapLastRouteAsAlert()
        try await alert.tapAction(title: Localizations.yes)
        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)

        subject.receive(.sessionTimeoutActionChanged(.lock))
        XCTAssertEqual(subject.state.sessionTimeoutAction, .lock)
    }

    /// `receive(_:)` with `sessionTimeoutActionChanged(:)` doesn't update the state if the value did not change.
    func test_receive_sessionTimeoutActionChanged_sameValue() async throws {
        subject.receive(.sessionTimeoutActionChanged(.logout))

        let alert = try coordinator.unwrapLastRouteAsAlert()
        try await alert.tapAction(title: Localizations.yes)
        XCTAssertEqual(subject.state.sessionTimeoutAction, .logout)

        subject.receive(.twoStepLoginPressed)
        let twoStepLoginAlert = try coordinator.unwrapLastRouteAsAlert()
        try await twoStepLoginAlert.tapAction(title: Localizations.cancel)

        // Should not show alert since the state's sessionTimeoutAction is already .logout
        subject.receive(.sessionTimeoutActionChanged(.logout))
        let lastShownAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(lastShownAlert, twoStepLoginAlert)
    }

    /// `receive(_:)` with `sessionTimeoutValueChanged(:)` updates the session timeout value in the state.
    func test_receive_sessionTimeoutValueChanged() {
        XCTAssertEqual(subject.state.sessionTimeoutValue, .immediately)
        subject.receive(.sessionTimeoutValueChanged(.never))
        XCTAssertEqual(subject.state.sessionTimeoutValue, .never)
    }

    /// `receive(_:)` with `.toggleApproveLoginRequestsToggle` updates the state.
    func test_receive_toggleApproveLoginRequestsToggle() {
        subject.state.isApproveLoginRequestsToggleOn = false
        subject.receive(.toggleApproveLoginRequestsToggle(true))

        XCTAssertTrue(subject.state.isApproveLoginRequestsToggleOn)
    }

    /// `receive(_:)` with `.toggleUnlockWithFaceID` updates the state.
    func test_receive_toggleUnlockWithFaceID() {
        subject.state.isUnlockWithFaceIDOn = false
        subject.receive(.toggleUnlockWithFaceID(true))

        XCTAssertTrue(subject.state.isUnlockWithFaceIDOn)
    }

    /// `receive(_:)` with `.toggleUnlockWithPINCode` updates the state.
    func test_receive_toggleUnlockWithPINCode() {
        subject.state.isUnlockWithPINCodeOn = false
        subject.receive(.toggleUnlockWithPINCode(true))

        XCTAssertTrue(subject.state.isUnlockWithPINCodeOn)
    }

    /// `receive(_:)` with `.toggleUnlockWithTouchID` updates the state.
    func test_receive_toggleUnlockWithTouchID() {
        subject.state.isUnlockWithTouchIDToggleOn = false
        subject.receive(.toggleUnlockWithTouchID(true))

        XCTAssertTrue(subject.state.isUnlockWithTouchIDToggleOn)
    }

    /// `receive(_:)` with `.twoStepLoginPressed` shows the two step login alert.
    func test_receive_twoStepLoginPressed() async throws {
        subject.receive(.twoStepLoginPressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.continueToWebApp)
        XCTAssertEqual(alert.message, Localizations.twoStepLoginDescriptionLong)
        XCTAssertEqual(alert.preferredStyle, .alert)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.cancel)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.yes)

        // Tapping yes navigates the user to the web app.
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertNotNil(subject.state.twoStepLoginUrl)
    }

    /// `state.twoStepLoginUrl` is initialized with the correct value.
    func test_twoStepLoginUrl() async throws {
        subject.receive(.twoStepLoginPressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(subject.state.twoStepLoginUrl, URL.example)
    }
}
