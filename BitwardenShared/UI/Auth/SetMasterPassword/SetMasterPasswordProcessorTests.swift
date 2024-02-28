import BitwardenSdk
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
    func test_perform_appeared_autoEnrollStatus_disabled() async {
        httpClient.result = .httpSuccess(testData: .organizationAutoEnrollStatusDisabled)

        await subject.perform(.appeared)

        XCTAssertFalse(subject.state.resetPasswordAutoEnroll)
    }

    /// `perform()` with `.appeared` loads the auto-enroll status for an organization which has it enabled.
    func test_perform_appeared_autoEnrollStatus_enabled() async {
        httpClient.result = .httpSuccess(testData: .organizationAutoEnrollStatus)

        await subject.perform(.appeared)

        XCTAssertTrue(subject.state.resetPasswordAutoEnroll)
    }

    /// `perform()` with `.appeared` syncs the user's vault and handles no master password policy.
    func test_perform_appeared_sync_noPolicy() async {
        authRepository.activeAccount = .fixture()
        policyService.getMasterPasswordPolicyOptionsResult = .success(nil)

        await subject.perform(.appeared)

        XCTAssertNil(subject.state.masterPasswordPolicy)
    }

    /// `perform()` with `.appeared` syncs the user's vault and loads the master password policy.
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
    func test_perform_appeared_error() async throws {
        authRepository.activeAccount = .fixture()
        httpClient.result = .httpSuccess(testData: .organizationAutoEnrollStatus)
        policyService.getMasterPasswordPolicyOptionsResult = .failure(BitwardenTestError.example)

        await subject.perform(.appeared)

        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [BitwardenTestError.example])
    }

    /// `perform()` with `.cancelPressed` has the coordinator dismiss the view.
    func test_perform_cancelPressed() async {
        await subject.perform(.cancelPressed)

        XCTAssertEqual(coordinator.routes, [.dismiss])
    }

    /// `perform()` with `.submitPressed` shows an alert if an error occurs.
    func test_perform_submitPressed_error() async throws {
        authRepository.setMasterPasswordResult = .failure(BitwardenTestError.example)

        subject.state.masterPassword = "PASSWORD1234"
        subject.state.masterPasswordRetype = "PASSWORD1234"
        subject.state.masterPasswordHint = "PASSWORD_HINT"
        subject.state.resetPasswordAutoEnroll = true

        await subject.perform(.submitPressed)

        XCTAssertEqual(coordinator.alertShown, [.networkResponseError(BitwardenTestError.example)])
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform()` with `.submitPressed` shows an alert if the master password field is empty.
    func test_perform_submitPressed_emptyPassword() async throws {
        await subject.perform(.submitPressed)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .inputValidationAlert(error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.masterPassword)
            ))
        )
    }

    /// `perform()` with `.submitPressed` shows an alert if the passwords don't match.
    func test_perform_submitPressed_passwordMismatch() async throws {
        subject.state.masterPassword = "NEW_PASSWORD"
        subject.state.masterPasswordRetype = "OTHER"

        await subject.perform(.submitPressed)

        XCTAssertEqual(coordinator.alertShown.last, .passwordsDontMatch)
    }

    /// `perform()` with `.submitPressed` shows an alert if the password doesn't satisfy the policy.
    func test_perform_submitPressed_policyWeakPassword() async throws {
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

        await subject.perform(.submitPressed)

        XCTAssertEqual(coordinator.alertShown.last, .masterPasswordInvalid())
    }

    /// `perform()` with `.submitPressed` shows an alert if the password is too short.
    func test_perform_submitPressed_passwordTooShort() async throws {
        subject.state.masterPassword = "ABC"
        subject.state.masterPasswordRetype = "ABC"

        await subject.perform(.submitPressed)

        XCTAssertEqual(coordinator.alertShown.last, .passwordIsTooShort)
    }

    /// `perform()` with `.submitPressed` submits the request for setting the master password.
    func test_perform_submitPressed_success() async throws {
        subject.state.masterPassword = "PASSWORD1234"
        subject.state.masterPasswordRetype = "PASSWORD1234"
        subject.state.masterPasswordHint = "PASSWORD_HINT"
        subject.state.resetPasswordAutoEnroll = true

        await subject.perform(.submitPressed)

        XCTAssertEqual(authRepository.setMasterPasswordHint, "PASSWORD_HINT")
        XCTAssertEqual(authRepository.setMasterPasswordPassword, "PASSWORD1234")
        XCTAssertEqual(authRepository.setMasterPasswordOrganizationId, "1234")
        XCTAssertEqual(authRepository.setMasterPasswordOrganizationIdentifier, "ORG_ID")
        XCTAssertEqual(authRepository.setMasterPasswordResetPasswordAutoEnroll, true)

        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
    }

    /// `receive(_:)` with `.masterPasswordChanged` updates the state to reflect the changes.
    func test_receive_masterPasswordChanged() {
        subject.state.masterPassword = ""

        subject.receive(.masterPasswordChanged("password"))
        XCTAssertEqual(subject.state.masterPassword, "password")
    }

    /// `receive()` with `.masterPasswordHintChanged` and a value updates the state to reflect the
    /// changes.
    func test_receive_masterPasswordHintChanged() {
        subject.state.masterPasswordHint = ""
        subject.receive(.masterPasswordHintChanged("this is password hint"))

        XCTAssertEqual(subject.state.masterPasswordHint, "this is password hint")
    }

    /// `receive(_:)` with `.masterPasswordRetypeChanged` updates the state to reflect the changes.
    func test_receive_masterPasswordRetypeChanged() {
        subject.state.masterPasswordRetype = ""

        subject.receive(.masterPasswordRetypeChanged("password"))
        XCTAssertEqual(subject.state.masterPasswordRetype, "password")
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
