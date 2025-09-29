import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - UserVerificationHelperTests

class UserVerificationHelperTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
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
        subject = DefaultUserVerificationHelper(
            authRepository: authRepository,
            errorReporter: errorReporter,
            localAuthService: localAuthService
        )
        subject.userVerificationDelegate = userVerificationDelegate
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

    /// `canVerifyDeviceLocalAuth()` verification for each status.
    func test_canVerifyDeviceLocalAuth() {
        localAuthService.deviceAuthenticationStatus = .authorized
        XCTAssertTrue(subject.canVerifyDeviceLocalAuth())

        localAuthService.deviceAuthenticationStatus = .notDetermined
        XCTAssertFalse(subject.canVerifyDeviceLocalAuth())

        localAuthService.deviceAuthenticationStatus = .cancelled
        XCTAssertFalse(subject.canVerifyDeviceLocalAuth())

        localAuthService.deviceAuthenticationStatus = .passcodeNotSet
        XCTAssertFalse(subject.canVerifyDeviceLocalAuth())

        localAuthService.deviceAuthenticationStatus = .unknownError("")
        XCTAssertFalse(subject.canVerifyDeviceLocalAuth())
    }

    /// `setupPin()` shows an alert for the user to enter a pin for their account.
    @MainActor
    func test_setupPin() async throws {
        userVerificationDelegate.alertShownHandler = { alert in
            XCTAssertEqual(alert, .enterPINCode { _ in })
            try alert.setText("1234", forTextFieldWithId: "pin")
            try await alert.tapAction(title: Localizations.submit)
        }

        try await subject.setupPin()

        XCTAssertEqual(authRepository.encryptedPin, "1234")
    }

    /// `setupPin()` throws an error if the entered pin is empty.
    @MainActor
    func test_setupPin_emptyPin() async throws {
        userVerificationDelegate.alertShownHandler = { alert in
            XCTAssertEqual(alert, .enterPINCode { _ in })
            try await alert.tapAction(title: Localizations.submit)
        }

        await assertAsyncThrows(error: Fido2Error.failedToSetupPin) {
            try await subject.setupPin()
        }
    }

    /// `setupPin()` throws an error if setting the pin fails.
    @MainActor
    func test_setupPin_error() async throws {
        authRepository.setPinsResult = .failure(BitwardenTestError.example)
        userVerificationDelegate.alertShownHandler = { alert in
            XCTAssertEqual(alert, .enterPINCode { _ in })
            try alert.setText("1234", forTextFieldWithId: "pin")
            try await alert.tapAction(title: Localizations.submit)
        }

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.setupPin()
        }

        XCTAssertEqual(authRepository.encryptedPin, "1234")
    }

    /// `setupPin()` throws an error if there's no delegate set up to display an alert.
    func test_setupPin_missingDelegate() async {
        subject.userVerificationDelegate = nil
        await assertAsyncThrows(error: Fido2Error.failedToSetupPin) {
            try await subject.setupPin()
        }
    }

    /// `setupPin()` with cancelled setup.
    @MainActor
    func test_setupPin_cancelled() async throws {
        let task = Task {
            try await self.subject.setupPin()
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

    /// `verifyDeviceLocalAuth()` with device status not authorized.
    func test_verifyDeviceLocalAuth_notAuthorized() async throws {
        localAuthService.deviceAuthenticationStatus = .notDetermined

        let result = try await subject.verifyDeviceLocalAuth(reason: "")

        XCTAssertEqual(result, .unableToPerform)
    }

    /// `verifyDeviceLocalAuth()` with authorized status and verified
    func test_verifyDeviceLocalAuth_verified() async throws {
        localAuthService.deviceAuthenticationStatus = .authorized
        localAuthService.evaluateDeviceOwnerPolicyResult = .success(true)

        let result = try await subject.verifyDeviceLocalAuth(reason: "")

        XCTAssertEqual(result, .verified)
    }

    /// `verifyDeviceLocalAuth()` with authorized status and not verified
    func test_verifyDeviceLocalAuth_not_verified() async throws {
        localAuthService.deviceAuthenticationStatus = .authorized
        localAuthService.evaluateDeviceOwnerPolicyResult = .success(false)

        let result = try await subject.verifyDeviceLocalAuth(reason: "")

        XCTAssertEqual(result, .notVerified)
    }

    /// `verifyDeviceLocalAuth()`  throws cancelled when evaluation throws `LAError.cancelled`
    func test_verifyDeviceLocalAuth_throwsCancelled() async throws {
        localAuthService.deviceAuthenticationStatus = .authorized
        localAuthService.evaluateDeviceOwnerPolicyResult = .failure(LocalAuthError.cancelled)

        await assertAsyncThrows(error: UserVerificationError.cancelled) {
            _ = try await subject.verifyDeviceLocalAuth(reason: "")
        }
    }

    /// `verifyDeviceLocalAuth()`  throws  what evaluation throws when no cancelled
    func test_verifyDeviceLocalAuth_throwsGeneral() async throws {
        localAuthService.deviceAuthenticationStatus = .authorized
        localAuthService.evaluateDeviceOwnerPolicyResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.verifyDeviceLocalAuth(reason: "")
        }
    }

    /// `verifyMasterPassword()` unable to perform when auth repository can't verify master password.
    func test_verifyMasterPassword_unableToperform() async throws {
        authRepository.canVerifyMasterPasswordResult = .success(false)

        let result = try await subject.verifyMasterPassword()

        XCTAssertEqual(result, .unableToPerform)
    }

    /// `verifyMasterPassword()` with valid master password.
    @MainActor
    func test_verifyMasterPassword_verified() async throws {
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
    @MainActor
    func test_verifyMasterPassword_notVerified() async throws {
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
    @MainActor
    func test_verifyMasterPassword_unableToPerformWhenThrowing() async throws {
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
        XCTAssertEqual(result, .unableToPerform)
    }

    /// `verifyMasterPassword()` with cancelled master password validation.
    @MainActor
    func test_verifyMasterPassword_cancelled() async throws {
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

    /// `verifyPin()` unable to perform when auth repository pin unlock is not available.
    func test_verifyPin_unableToPerform() async throws {
        authRepository.isPinUnlockAvailableResult = .success(false)

        let result = try await subject.verifyPin()

        XCTAssertEqual(result, .unableToPerform)
    }

    /// `verifyPin()` with cancelled verification.
    @MainActor
    func test_verifyPin_cancelled() async throws {
        authRepository.isPinUnlockAvailableResult = .success(true)
        let task = Task {
            try await self.subject.verifyPin()
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

    /// `verifyPin()` with verified PIN.
    @MainActor
    func test_verifyPin_verified() async throws {
        authRepository.isPinUnlockAvailableResult = .success(true)
        authRepository.validatePinResult = .success(true)

        let task = Task {
            try await self.subject.verifyPin()
        }

        try await waitForAsync {
            !self.userVerificationDelegate.alertShown.isEmpty
        }

        try await enterPinInAlertAndSubmit()

        let result = try await task.value

        XCTAssertEqual(result, .verified)
    }

    /// `verifyPin()` with not verified PIN.
    @MainActor
    func test_verifyPin_notVerified() async throws {
        authRepository.isPinUnlockAvailableResult = .success(true)
        authRepository.validatePinResult = .success(false)

        let task = Task {
            try await self.subject.verifyPin()
        }

        try await waitForAsync {
            !self.userVerificationDelegate.alertShown.isEmpty
        }

        try await enterPinInAlertAndSubmit()

        try await waitForAsync {
            self.userVerificationDelegate.alertShown
                .last?.title == Localizations.invalidPIN
        }

        let alert = try XCTUnwrap(userVerificationDelegate.alertShown.last)

        XCTAssertEqual(alert, .defaultAlert(title: Localizations.invalidPIN))

        try await alert.tapAction(title: Localizations.ok)

        userVerificationDelegate.alertOnDismissed?()

        let result = try await task.value

        XCTAssertEqual(result, .notVerified)
    }

    /// `verifyPin()` with throwing pin verification returns unable to perform.
    @MainActor
    func test_verifyPin_throwsUnableToPerform() async throws {
        authRepository.isPinUnlockAvailableResult = .success(true)
        authRepository.validatePinResult = .failure(BitwardenTestError.example)

        let task = Task {
            try await self.subject.verifyPin()
        }

        try await waitForAsync {
            !self.userVerificationDelegate.alertShown.isEmpty
        }

        try await enterPinInAlertAndSubmit()

        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }

        let result = try await task.value

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
        XCTAssertEqual(result, .unableToPerform)
    }

    // MARK: Private

    @MainActor
    private func enterMasterPasswordInAlertAndSubmit() async throws {
        let alert = try XCTUnwrap(userVerificationDelegate.alertShown.last)
        XCTAssertEqual(alert, .masterPasswordPrompt { _ in })

        try alert.setText("password", forTextFieldWithId: "password")
        try await alert.tapAction(title: Localizations.submit)
    }

    @MainActor
    private func enterPinInAlertAndSubmit() async throws {
        let alert = try XCTUnwrap(userVerificationDelegate.alertShown.last)
        XCTAssertEqual(alert, .enterPINCode(settingUp: false) { _ in })

        try alert.setText("pin", forTextFieldWithId: "pin")
        try await alert.tapAction(title: Localizations.submit)
    }
}

class MockUserVerificationHelperDelegate: UserVerificationDelegate {
    var alertShown = [Alert]()
    var alertShownHandler: ((Alert) async throws -> Void)?
    var alertOnDismissed: (() -> Void)?

    func showAlert(_ alert: Alert) {
        alertShown.append(alert)
        Task {
            do {
                try await alertShownHandler?(alert)
            } catch {
                XCTFail("Error calling alert shown handler: \(error)")
            }
        }
    }

    func showAlert(_ alert: BitwardenShared.Alert, onDismissed: (() -> Void)?) {
        showAlert(alert)
        alertOnDismissed = onDismissed
    }
} // swiftlint:disable:this file_length
