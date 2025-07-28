import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - UpdateMasterPasswordProcessorTests

// swiftlint:disable:next type_body_length
class UpdateMasterPasswordProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var httpClient: MockHTTPClient!
    var policyService: MockPolicyService!
    var settingsRepository: MockSettingsRepository!
    var stateService: MockStateService!
    var subject: UpdateMasterPasswordProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        authRepository = MockAuthRepository()
        authService = MockAuthService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        httpClient = MockHTTPClient()
        policyService = MockPolicyService()
        settingsRepository = MockSettingsRepository()
        stateService = MockStateService()

        let services = ServiceContainer.withMocks(
            authRepository: authRepository,
            authService: authService,
            errorReporter: errorReporter,
            httpClient: httpClient,
            policyService: policyService,
            settingsRepository: settingsRepository,
            stateService: stateService
        )
        let state = UpdateMasterPasswordState()
        subject = UpdateMasterPasswordProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: state
        )
    }

    override func tearDown() {
        super.tearDown()
        authRepository = nil
        authService = nil
        coordinator = nil
        errorReporter = nil
        httpClient = nil
        settingsRepository = nil
        subject = nil
        stateService = nil
    }

    // MARK: Tests

    /// `perform()` with `.appeared` fails to sync and move to main vault screen.
    @MainActor
    func test_perform_appeared_fails() async throws {
        authRepository.activeAccount = .fixture()
        struct CryptoError: Error, Equatable {}
        policyService.getMasterPasswordPolicyOptionsResult = .failure(CryptoError())
        XCTAssertNil(subject.state.masterPasswordPolicy)
        await subject.perform(.appeared)
        XCTAssertNil(subject.state.masterPasswordPolicy)
        XCTAssertNil(coordinator.routes.last)
        XCTAssertEqual(errorReporter.errors.last as? CryptoError, CryptoError())
    }

    /// `perform()` with `.appeared` syncs vault and fetches `MasterPasswordPolicyOption`
    /// updates the state.
    @MainActor
    func test_perform_appeared_success() async throws {
        authRepository.activeAccount = .fixture()
        policyService.getMasterPasswordPolicyOptionsResult = .success(
            MasterPasswordPolicyOptions(
                minComplexity: 3,
                minLength: 4,
                requireUpper: true,
                requireLower: true,
                requireNumbers: true,
                requireSpecial: true,
                enforceOnLogin: true
            )
        )
        XCTAssertNil(subject.state.masterPasswordPolicy)
        await subject.perform(.appeared)
        XCTAssertNotNil(subject.state.masterPasswordPolicy)
        XCTAssertEqual(subject.state.userEmail, Account.fixture().profile.email)
    }

    /// `perform()` with `.appeared` succeeds to sync but master password policy fails to load,
    /// and move to main vault screen.
    @MainActor
    func test_perform_appeared_succeeds_policyNil() async throws {
        authRepository.activeAccount = .fixture(
            profile: .fixture(forcePasswordResetReason: .weakMasterPasswordOnLogin)
        )
        policyService.getMasterPasswordPolicyOptionsResult = .success(nil)
        stateService.activeAccount = .fixture()

        XCTAssertNil(subject.state.masterPasswordPolicy)
        await subject.perform(.appeared)
        XCTAssertNil(subject.state.masterPasswordPolicy)
        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
    }

    /// `perform()` with `.appeared` succeeds to sync but doesn't navigate for account recovery with
    /// no policy.
    @MainActor
    func test_perform_appeared_succeeds_policyNilAccountRecovery() async throws {
        authRepository.activeAccount = .fixture()
        policyService.getMasterPasswordPolicyOptionsResult = .success(nil)
        XCTAssertNil(subject.state.masterPasswordPolicy)
        await subject.perform(.appeared)
        XCTAssertNil(subject.state.masterPasswordPolicy)
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `perform()` with `.logoutTapped` logs the user out.
    @MainActor
    func test_perform_logoutTapped() async throws {
        await subject.perform(.logoutTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.logOut)
        XCTAssertEqual(alert.message, Localizations.logoutConfirmation)
        XCTAssertEqual(alert.preferredStyle, .alert)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(
            coordinator.events.last,
            .action(
                .logout(userId: nil, userInitiated: true)
            )
        )
    }

    /// `perform()` with `.saveTapped` shows an alert if an error occurs.
    @MainActor
    func test_perform_saveTapped_error() async throws {
        authRepository.updateMasterPasswordResult = .failure(BitwardenTestError.example)

        subject.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        subject.state.currentMasterPassword = "PASSWORD"
        subject.state.masterPassword = "NEW_PASSWORD"
        subject.state.masterPasswordRetype = "NEW_PASSWORD"
        subject.state.masterPasswordHint = "NEW_PASSWORD_HINT"

        await subject.perform(.saveTapped)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform()` with `.saveTapped` shows an alert if the master password field is empty.
    @MainActor
    func test_perform_saveTapped_emptyPassword() async throws {
        subject.state.forcePasswordResetReason = .weakMasterPasswordOnLogin

        await subject.perform(.saveTapped)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .inputValidationAlert(error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.masterPassword)
            ))
        )
    }

    /// `perform()` with `.saveTapped` shows an alert if the password is invalid.
    @MainActor
    func test_perform_saveTapped_passwordInvalid() async throws {
        subject.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        subject.state.masterPassword = "NEW_PASSWORD"
        subject.state.masterPasswordRetype = "OTHER"

        await subject.perform(.saveTapped)

        XCTAssertEqual(coordinator.alertShown.last, .passwordsDontMatch)
    }

    /// `perform()` with `.saveTapped` shows an alert if the password doesn't satisfy the policy.
    @MainActor
    func test_perform_saveTapped_passwordMismatch() async throws {
        authService.requirePasswordChangeResult = .success(true)
        authRepository.activeAccount = .fixture()
        subject.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        subject.state.masterPasswordPolicy = MasterPasswordPolicyOptions(
            minComplexity: 3,
            minLength: 12,
            requireUpper: false,
            requireLower: false,
            requireNumbers: false,
            requireSpecial: false,
            enforceOnLogin: true
        )

        subject.state.masterPassword = "INVALID"
        subject.state.masterPasswordRetype = "INVALID"

        await subject.perform(.saveTapped)

        XCTAssertEqual(coordinator.alertShown.last, .masterPasswordInvalid())
    }

    /// `perform()` with `.saveTapped` shows an alert if the password is too short.
    @MainActor
    func test_perform_saveTapped_passwordTooShort() async throws {
        subject.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        subject.state.masterPassword = "ABC"
        subject.state.masterPasswordRetype = "ABC"

        await subject.perform(.saveTapped)

        XCTAssertEqual(coordinator.alertShown.last, .passwordIsTooShort)
    }

    /// `perform()` with `.saveTapped` submits the request for updating the master password.
    @MainActor
    func test_perform_saveTapped_success() async throws {
        subject.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        subject.state.currentMasterPassword = "PASSWORD"
        subject.state.masterPassword = "NEW_PASSWORD"
        subject.state.masterPasswordRetype = "NEW_PASSWORD"
        subject.state.masterPasswordHint = "NEW_PASSWORD_HINT"

        await subject.perform(.saveTapped)

        XCTAssertEqual(authRepository.updateMasterPasswordCurrentPassword, "PASSWORD")
        XCTAssertEqual(authRepository.updateMasterPasswordNewPassword, "NEW_PASSWORD")
        XCTAssertEqual(authRepository.updateMasterPasswordPasswordHint, "NEW_PASSWORD_HINT")
        XCTAssertEqual(authRepository.updateMasterPasswordReason, .weakMasterPasswordOnLogin)

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
        XCTAssertEqual(coordinator.routes, [.dismiss])
    }

    /// `receive(_:)` with `.currentMasterPasswordChanged` updates the state to reflect the changes.
    @MainActor
    func test_receive_currentMasterPasswordChanged() {
        subject.state.currentMasterPassword = ""

        subject.receive(.currentMasterPasswordChanged("password"))
        XCTAssertEqual(subject.state.currentMasterPassword, "password")
    }

    /// `receive(_:)` with `.masterPasswordChanged` updates the state to reflect the changes.
    @MainActor
    func test_receive_masterPasswordChanged() {
        subject.state.masterPassword = ""

        subject.receive(.masterPasswordChanged("password"))
        XCTAssertEqual(subject.state.masterPassword, "password")
    }

    /// `receive(_:)` with `.masterPasswordChanged(_:)` updates the password strength score based on
    /// the entered password.
    @MainActor
    func test_receive_masterPasswordChanged_updatesPasswordStrength() {
        subject.state.userEmail = "user@bitwarden.com"
        subject.receive(.masterPasswordChanged(""))
        XCTAssertNil(subject.state.passwordStrengthScore)
        XCTAssertNil(authRepository.passwordStrengthPassword)

        authRepository.passwordStrengthResult = .success(0)
        subject.receive(.masterPasswordChanged("T"))
        waitFor(subject.state.passwordStrengthScore == 0)
        XCTAssertEqual(authRepository.passwordStrengthEmail, "user@bitwarden.com")
        XCTAssertFalse(authRepository.passwordStrengthIsPreAuth)
        XCTAssertEqual(authRepository.passwordStrengthPassword, "T")

        authRepository.passwordStrengthResult = .success(4)
        subject.receive(.masterPasswordChanged("TestPassword1234567890!@#"))
        waitFor(subject.state.passwordStrengthScore == 4)
        XCTAssertEqual(authRepository.passwordStrengthEmail, "user@bitwarden.com")
        XCTAssertFalse(authRepository.passwordStrengthIsPreAuth)
        XCTAssertEqual(authRepository.passwordStrengthPassword, "TestPassword1234567890!@#")
    }

    /// `receive(_:)` with `.masterPasswordChanged(_:)` records an error if the `.passwordStrength()` throws.
    @MainActor
    func test_receive_masterPasswordChanged_updatePasswordStrength_fails() {
        authRepository.passwordStrengthResult = .failure(BitwardenTestError.example)
        subject.receive(.masterPasswordChanged("T"))
        waitFor(!errorReporter.errors.isEmpty)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, BitwardenTestError.example)
    }

    /// `receive(_:)` with `.masterPasswordRetypeChanged` updates the state to reflect the changes.
    @MainActor
    func test_receive_masterPasswordRetypeChanged() {
        subject.state.masterPasswordRetype = ""

        subject.receive(.masterPasswordRetypeChanged("password"))
        XCTAssertEqual(subject.state.masterPasswordRetype, "password")
    }

    /// `receive()` with `.masterPasswordHintChanged` and a value updates the state to reflect the
    /// changes.
    @MainActor
    func test_receive_masterPasswordHintChanged() {
        subject.state.masterPasswordHint = ""
        subject.receive(.masterPasswordHintChanged("this is password hint"))

        XCTAssertEqual(subject.state.masterPasswordHint, "this is password hint")
    }

    /// `receive(_:)` with `.preventAccountLockTapped` navigates to the right route.
    @MainActor
    func test_receive_preventAccountLock() {
        subject.receive(.preventAccountLockTapped)
        XCTAssertEqual(coordinator.routes.last, .preventAccountLock)
    }

    /// `receive(_:)` with `.revealCurrentMasterPasswordFieldPressed` updates the state to reflect the changes.
    @MainActor
    func test_receive_revealCurrentMasterPasswordFieldPressed() {
        subject.state.isCurrentMasterPasswordRevealed = false
        subject.receive(.revealCurrentMasterPasswordFieldPressed(true))
        XCTAssertTrue(subject.state.isCurrentMasterPasswordRevealed)

        subject.receive(.revealCurrentMasterPasswordFieldPressed(false))
        XCTAssertFalse(subject.state.isCurrentMasterPasswordRevealed)
    }

    /// `receive(_:)` with `.revealMasterPasswordFieldPressed` updates the state to reflect the changes.
    @MainActor
    func test_receive_revealMasterPasswordFieldPressed() {
        subject.state.isMasterPasswordRevealed = false
        subject.receive(.revealMasterPasswordFieldPressed(true))
        XCTAssertTrue(subject.state.isMasterPasswordRevealed)

        subject.receive(.revealMasterPasswordFieldPressed(false))
        XCTAssertFalse(subject.state.isMasterPasswordRevealed)
    }

    /// `receive(_:)` with `.revealMasterPasswordRetypeFieldPressed` updates the state to reflect the changes.
    @MainActor
    func test_receive_revealMasterPasswordRetypeFieldPressed() {
        subject.state.isMasterPasswordRetypeRevealed = false
        subject.receive(.revealMasterPasswordRetypeFieldPressed(true))
        XCTAssertTrue(subject.state.isMasterPasswordRetypeRevealed)

        subject.receive(.revealMasterPasswordRetypeFieldPressed(false))
        XCTAssertFalse(subject.state.isMasterPasswordRetypeRevealed)
    }
}
