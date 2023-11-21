import XCTest

@testable import BitwardenShared

class AccountSecurityProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var errorReporter: MockErrorReporter!
    var settingsRepository: MockSettingsRepository!
    var stateService: MockStateService!
    var subject: AccountSecurityProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        errorReporter = MockErrorReporter()
        settingsRepository = MockSettingsRepository()
        stateService = MockStateService()
        subject = AccountSecurityProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                settingsRepository: settingsRepository,
                stateService: stateService
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
        await alert.alertActions[0].handler?(alert.alertActions[0])

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
        await alert.alertActions[0].handler?(alert.alertActions[0])

        XCTAssertEqual(
            errorReporter.errors as? [StateServiceError],
            [StateServiceError.noActiveAccount]
        )
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
}
