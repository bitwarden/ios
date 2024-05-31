import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - UserVerificationHelperTests

class UserVerificationHelperTests: BitwardenTestCase {
    // MARK: Types

    typealias VerifyFunction = () async throws -> UserVerificationResult

    // MARK: Properties

    var authRepository: MockAuthRepository!
    var errorReporter: MockErrorReporter!
    var localAuthService: MockLocalAuthService!
    var subject: UserVerificationHelper!
    var userVerificationDelegate: MockUserVerificationHelperDelegate!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        userVerificationDelegate = MockUserVerificationHelperDelegate()
        authRepository = MockAuthRepository()
        errorReporter = MockErrorReporter()
        localAuthService = MockLocalAuthService()
        let services = ServiceContainer.withMocks(
            authRepository: authRepository,
            errorReporter: errorReporter,
            localAuthService: localAuthService
        )
        subject = DefaultUserVerificationHelper(userVerificationDelegate: userVerificationDelegate, services: services)
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        errorReporter = nil
        localAuthService = nil
        userVerificationDelegate = nil
        subject = nil
    }

    // MARK: Tests

    /// `verifyDeviceLocalAuth()` with device status not authorized.
    func test_verifyDeviceLocalAuth_cant_perform_when_not_authorized() async throws {
        localAuthService.deviceAuthenticationStatus = .notDetermined

        let result = try await subject.verifyDeviceLocalAuth(because: "")

        XCTAssertEqual(result, .cantPerform)
    }

    /// `verifyDeviceLocalAuth()` with authorized status and verified
    func test_verifyDeviceLocalAuth_verified_when_authorized_and_valid_evaluation() async throws {
        localAuthService.deviceAuthenticationStatus = .authorized
        localAuthService.evaluateDeviceOwnerPolicyResult = .success(true)

        let result = try await subject.verifyDeviceLocalAuth(because: "")

        XCTAssertEqual(result, .verified)
    }

    /// `verifyDeviceLocalAuth()` with authorized status and not verified
    func test_verifyDeviceLocalAuth_not_verified_when_authorized_and_invalid_evaluation() async throws {
        localAuthService.deviceAuthenticationStatus = .authorized
        localAuthService.evaluateDeviceOwnerPolicyResult = .success(false)

        let result = try await subject.verifyDeviceLocalAuth(because: "")

        XCTAssertEqual(result, .notVerified)
    }

    /// `verifyDeviceLocalAuth()`  throws cancelled when evaluation thorws `LAError.cancelled`
    func test_verifyDeviceLocalAuth_throws_cancelled_when_authorized_and_throwing_evaluation() async throws {
        localAuthService.deviceAuthenticationStatus = .authorized
        localAuthService.evaluateDeviceOwnerPolicyResult = .failure(LocalAuthError.cancelled)

        await assertAsyncThrows(error: UserVerificationError.cancelled) {
            _ = try await subject.verifyDeviceLocalAuth(because: "")
        }
    }

    /// `verifyDeviceLocalAuth()`  throws  what evaluation thorws when no cancelled
    func test_verifyDeviceLocalAuth_throws_when_authorized_and_throwing_evaluation() async throws {
        localAuthService.deviceAuthenticationStatus = .authorized
        localAuthService.evaluateDeviceOwnerPolicyResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.verifyDeviceLocalAuth(because: "")
        }
    }

    /// `verifyMasterPassword()` can't perform when auth repository can't verify master password.
    func test_verifyMasterPassword_cant_perform_because_auth_repo_cant_verify() async throws {
        authRepository.canVerifyMasterPasswordResult = .success(false)

        let result = try await subject.verifyMasterPassword()

        XCTAssertEqual(result, .cantPerform)
    }

    /// `verifyMasterPassword()` with valid master password.
    func test_verifyMasterPassword_verified_when_validateMasterPassword_success() async throws {
        authRepository.validatePasswordResult = .success(true)

        var result: UserVerificationResult?

        let task = Task {
            try await self.subject.verifyMasterPassword()
        }

        try await waitForAsync {
            !self.userVerificationDelegate.alertShown.isEmpty
        }

        try await enterMasterPasswordInAlertAndSubmit()

        result = try await task.value

        XCTAssertEqual(result, .verified)
    }

    /// `verifyMasterPassword()` with invalid master password.
    func test_verifyMasterPassword_verified_when_validateMasterPassword_invalid() async throws {
        authRepository.validatePasswordResult = .success(false)

        var result: UserVerificationResult?

        let task = Task {
            try await self.subject.verifyMasterPassword()
        }

        try await waitForAsync {
            !self.userVerificationDelegate.alertShown.isEmpty
        }

        try await enterMasterPasswordInAlertAndSubmit()

        try await waitForAsync {
            self.userVerificationDelegate.alertShown
                .last?.title == Localizations.invalidMasterPassword
        }

        let alert = try XCTUnwrap(userVerificationDelegate.alertShown.last)

        XCTAssertEqual(alert, .defaultAlert(title: Localizations.invalidMasterPassword))

        try await alert.tapAction(title: Localizations.ok)

        userVerificationDelegate.alertOnDismissed?()

        result = try await task.value

        XCTAssertEqual(result, .notVerified)
    }

    /// `verifyMasterPassword()` with throwing master password validation.
    func test_verifyMasterPassword_verified_when_validateMasterPassword_throws() async throws {
        authRepository.validatePasswordResult = .failure(BitwardenTestError.example)

        var result: UserVerificationResult?

        let task = Task {
            try await self.subject.verifyMasterPassword()
        }

        try await waitForAsync {
            !self.userVerificationDelegate.alertShown.isEmpty
        }

        try await enterMasterPasswordInAlertAndSubmit()

        result = try await task.value

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
        XCTAssertEqual(result, .cantPerform)
    }

    /// `verifyMasterPassword()` with cancelled master password validation.
    func test_verifyMasterPassword_verified_when_validateMasterPassword_is_cancelled() async throws {
        let task = Task {
            try await self.subject.verifyMasterPassword()
        }

        try await waitForAsync {
            !self.userVerificationDelegate.alertShown.isEmpty
        }

        let alert = try XCTUnwrap(userVerificationDelegate.alertShown.last)
        try await alert.tapAction(title: Localizations.cancel)

        await assertAsyncThrows(error: UserVerificationError.cancelled) {
            _ = try await task.value
        }
    }

    /// `verifyPin()` can't perform when auth repository pin unlock is not available.
    func test_verifyPin_cant_perform_because_auth_repo_pin_unlock_is_not_available() async throws {
        authRepository.isPinUnlockAvailableResult = .success(false)

        let result = try await subject.verifyPin()

        XCTAssertEqual(result, .cantPerform)
    }

    // TODO: PM-8388 Add more tests for `verifyPin`

    // MARK: Private

    private func enterMasterPasswordInAlertAndSubmit() async throws {
        let alert = try XCTUnwrap(userVerificationDelegate.alertShown.last)

        XCTAssertEqual(alert, .masterPasswordPrompt { _ in })
        var textField = try XCTUnwrap(alert.alertTextFields.first)
        textField = AlertTextField(id: "password", text: "password")

        try await alert.tapAction(title: Localizations.submit, alertTextFields: [textField])
    }
}

class MockUserVerificationHelperDelegate: UserVerificationDelegate {
    var alertShown = [Alert]()
    var alertOnDismissed: (() -> Void)?

    func showAlert(_ alert: BitwardenShared.Alert, onDismissed: (() -> Void)?) {
        alertShown.append(alert)
        alertOnDismissed = onDismissed
    }
}
