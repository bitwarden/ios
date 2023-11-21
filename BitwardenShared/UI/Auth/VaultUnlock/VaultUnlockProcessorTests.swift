import XCTest

@testable import BitwardenShared

class VaultUnlockProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<AuthRoute>!
    var subject: VaultUnlockProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator()

        subject = VaultUnlockProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(authRepository: authRepository),
            state: VaultUnlockState(account: .fixture())
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.unlockVault` attempts to unlock the vault with the entered password.
    func test_perform_unlockVault() async throws {
        subject.state.masterPassword = "password"

        await subject.perform(.unlockVault)

        XCTAssertEqual(authRepository.unlockVaultPassword, "password")
        XCTAssertEqual(coordinator.routes.last, .complete)
    }

    /// `perform(_:)` with `.unlockVault` shows an alert if the master password is empty.
    func test_perform_unlockVault_InputValidationError() async throws {
        await subject.perform(.unlockVault)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(
            alert,
            Alert.inputValidationAlert(error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.masterPassword)
            ))
        )
    }

    /// `perform(_:)` with `.unlockVault` shows an alert if the master password was incorrect.
    func test_perform_unlockVault_invalidPasswordError() async throws {
        subject.state.masterPassword = "password"

        struct VaultUnlockError: Error {}
        authRepository.unlockVaultResult = .failure(VaultUnlockError())

        await subject.perform(.unlockVault)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.invalidMasterPassword
            )
        )
    }

    /// `receive(_:)` with `.masterPasswordChanged` updates the state to reflect the changes.
    func test_receive_masterPasswordChanged() {
        subject.state.masterPassword = ""

        subject.receive(.masterPasswordChanged("password"))
        XCTAssertEqual(subject.state.masterPassword, "password")
    }

    /// `receive(_:)` with `.morePressed` navigates to the login options screen and allows the user
    /// to logout.
    func test_receive_morePressed_logout() async throws {
        subject.receive(.morePressed)

        let optionsAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(optionsAlert.title, Localizations.options)
        XCTAssertNil(optionsAlert.message)
        XCTAssertEqual(optionsAlert.preferredStyle, .actionSheet)
        XCTAssertEqual(optionsAlert.alertActions.count, 2)
        XCTAssertEqual(optionsAlert.alertActions[0].title, Localizations.logOut)
        XCTAssertEqual(optionsAlert.alertActions[1].title, Localizations.cancel)

        await optionsAlert.alertActions[0].handler?(optionsAlert.alertActions[0], [])

        let logoutConfirmationAlert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(logoutConfirmationAlert.title, Localizations.logOut)
        XCTAssertEqual(logoutConfirmationAlert.message, Localizations.logoutConfirmation)
        XCTAssertEqual(logoutConfirmationAlert.preferredStyle, .alert)
        XCTAssertEqual(logoutConfirmationAlert.alertActions.count, 2)
        XCTAssertEqual(logoutConfirmationAlert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(logoutConfirmationAlert.alertActions[1].title, Localizations.cancel)

        await logoutConfirmationAlert.alertActions[0].handler?(optionsAlert.alertActions[0], [])

        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertEqual(coordinator.routes.last, .landing)
    }

    /// `receive(_:)` with `.revealMasterPasswordFieldPressed` updates the state to reflect the changes.
    func test_receive_revealMasterPasswordFieldPressed() {
        subject.state.isMasterPasswordRevealed = false
        subject.receive(.revealMasterPasswordFieldPressed(true))
        XCTAssertTrue(subject.state.isMasterPasswordRevealed)

        subject.receive(.revealMasterPasswordFieldPressed(false))
        XCTAssertFalse(subject.state.isMasterPasswordRevealed)
    }
}
