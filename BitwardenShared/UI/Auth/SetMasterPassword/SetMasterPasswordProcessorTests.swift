import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

class SetMasterPasswordProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var httpClient: MockHTTPClient!
    var policyService: MockPolicyService!
    var settingsRepository: MockSettingsRepository!
    var stateService: MockStateService!
    var subject: SetMasterPasswordProcessor!

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
        let state = SetMasterPasswordState(organizationId: "1234", organizationIdentifier: "ORG_ID")
        subject = SetMasterPasswordProcessor(
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

    /// `perform()` with `.appeared` loads the auto-enroll status for an organization which has it disabled.
    @MainActor
    func test_perform_appeared_autoEnrollStatus_disabled() async {
        httpClient.result = .httpSuccess(testData: .organizationAutoEnrollStatusDisabled)

        await subject.perform(.appeared)

        XCTAssertFalse(subject.state.resetPasswordAutoEnroll)
    }

    /// `perform()` with `.appeared` loads the auto-enroll status for an organization which has it enabled.
    @MainActor
    func test_perform_appeared_autoEnrollStatus_enabled() async {
        authRepository.activeAccount = .fixture()
        httpClient.result = .httpSuccess(testData: .organizationAutoEnrollStatus)

        await subject.perform(.appeared)

        XCTAssertTrue(subject.state.resetPasswordAutoEnroll)
    }

    /// `perform()` with `.appeared` syncs the user's vault and handles no master password policy.
    @MainActor
    func test_perform_appeared_sync_noPolicy() async {
        authRepository.activeAccount = .fixture()
        policyService.getMasterPasswordPolicyOptionsResult = .success(nil)

        await subject.perform(.appeared)

        XCTAssertNil(subject.state.masterPasswordPolicy)
    }

    /// `perform()` with `.appeared` syncs the user's vault and loads the master password policy.
    @MainActor
    func test_perform_appeared_sync_withPolicy() async {
        authRepository.activeAccount = .fixture()
        httpClient.result = .httpSuccess(testData: .organizationAutoEnrollStatus)
        let policy = MasterPasswordPolicyOptions(
            minComplexity: 3,
            minLength: 4,
            requireUpper: true,
            requireLower: true,
            requireNumbers: true,
            requireSpecial: true,
            enforceOnLogin: true
        )
        policyService.getMasterPasswordPolicyOptionsResult = .success(policy)
        XCTAssertNil(subject.state.masterPasswordPolicy)

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.masterPasswordPolicy, policy)
    }

    /// `perform()` with `.appeared` fails to fetch the policy and shows an alert.
    @MainActor
    func test_perform_appeared_error() async throws {
        authRepository.activeAccount = .fixture()
        httpClient.result = .httpSuccess(testData: .organizationAutoEnrollStatus)
        policyService.getMasterPasswordPolicyOptionsResult = .failure(BitwardenTestError.example)

        await subject.perform(.appeared)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [BitwardenTestError.example])
    }

    /// `perform()` with `.cancelPressed` has the coordinator dismiss the view.
    @MainActor
    func test_perform_cancelPressed() async {
        await subject.perform(.cancelPressed)

        XCTAssertEqual(coordinator.routes, [.dismiss])
    }

    /// `perform()` with `.saveTapped` shows an alert if an error occurs.
    @MainActor
    func test_perform_saveTapped_error() async throws {
        authRepository.setMasterPasswordResult = .failure(BitwardenTestError.example)

        subject.state.masterPassword = "PASSWORD1234"
        subject.state.masterPasswordRetype = "PASSWORD1234"
        subject.state.masterPasswordHint = "PASSWORD_HINT"
        subject.state.resetPasswordAutoEnroll = true

        await subject.perform(.saveTapped)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform()` with `.saveTapped` shows an alert if the master password field is empty.
    @MainActor
    func test_perform_saveTapped_emptyPassword() async throws {
        await subject.perform(.saveTapped)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .inputValidationAlert(error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.masterPassword)
            ))
        )
    }

    /// `perform()` with `.saveTapped` shows an alert if the passwords don't match.
    @MainActor
    func test_perform_saveTapped_passwordMismatch() async throws {
        subject.state.masterPassword = "NEW_PASSWORD"
        subject.state.masterPasswordRetype = "OTHER"

        await subject.perform(.saveTapped)

        XCTAssertEqual(coordinator.alertShown.last, .passwordsDontMatch)
    }

    /// `perform()` with `.saveTapped` shows an alert if the password doesn't satisfy the policy.
    @MainActor
    func test_perform_saveTapped_policyWeakPassword() async throws {
        authService.requirePasswordChangeResult = .success(true)
        authRepository.activeAccount = .fixture()
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
        subject.state.masterPassword = "ABC"
        subject.state.masterPasswordRetype = "ABC"

        await subject.perform(.saveTapped)

        XCTAssertEqual(coordinator.alertShown.last, .passwordIsTooShort)
    }

    /// `perform()` with `.saveTapped` submits the request for setting the master password.
    @MainActor
    func test_perform_saveTapped_success() async throws {
        subject.state.masterPassword = "PASSWORD1234"
        subject.state.masterPasswordRetype = "PASSWORD1234"
        subject.state.masterPasswordHint = "PASSWORD_HINT"
        subject.state.resetPasswordAutoEnroll = true

        await subject.perform(.saveTapped)

        XCTAssertEqual(authRepository.setMasterPasswordHint, "PASSWORD_HINT")
        XCTAssertEqual(authRepository.setMasterPasswordPassword, "PASSWORD1234")
        XCTAssertEqual(authRepository.setMasterPasswordOrganizationId, "1234")
        XCTAssertEqual(authRepository.setMasterPasswordOrganizationIdentifier, "ORG_ID")
        XCTAssertEqual(authRepository.setMasterPasswordResetPasswordAutoEnroll, true)

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
    }

    /// `receive(_:)` with `.masterPasswordChanged` updates the state to reflect the changes.
    @MainActor
    func test_receive_masterPasswordChanged() {
        subject.state.masterPassword = ""

        subject.receive(.masterPasswordChanged("password"))
        XCTAssertEqual(subject.state.masterPassword, "password")
    }

    /// `receive()` with `.masterPasswordHintChanged` and a value updates the state to reflect the
    /// changes.
    @MainActor
    func test_receive_masterPasswordHintChanged() {
        subject.state.masterPasswordHint = ""
        subject.receive(.masterPasswordHintChanged("this is password hint"))

        XCTAssertEqual(subject.state.masterPasswordHint, "this is password hint")
    }

    /// `receive(_:)` with `.masterPasswordRetypeChanged` updates the state to reflect the changes.
    @MainActor
    func test_receive_masterPasswordRetypeChanged() {
        subject.state.masterPasswordRetype = ""

        subject.receive(.masterPasswordRetypeChanged("password"))
        XCTAssertEqual(subject.state.masterPasswordRetype, "password")
    }

    /// `receive(_:)` with `.preventAccountLockTapped` navigates to the right route.
    @MainActor
    func test_receive_preventAccountLock() {
        subject.receive(.preventAccountLockTapped)
        XCTAssertEqual(coordinator.routes.last, .preventAccountLock)
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
}
