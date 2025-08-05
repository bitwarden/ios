import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - Fido2UserVerificationMediatorTests

class Fido2UserVerificationMediatorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Types

    typealias VerifyFunction = () async throws -> UserVerificationResult

    // MARK: Properties

    var authRepository: MockAuthRepository!
    var errorReporter: MockErrorReporter!
    var fido2UserVerificationMediatorDelegate: MockFido2UserVerificationMediatorDelegate!
    var stateService: MockStateService!
    var subject: Fido2UserVerificationMediator!
    var userVerificationHelper: MockUserVerificationHelper!
    var userVerificationRunner: MockUserVerificationRunner!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        fido2UserVerificationMediatorDelegate = MockFido2UserVerificationMediatorDelegate()
        authRepository = MockAuthRepository()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        userVerificationHelper = MockUserVerificationHelper()
        userVerificationRunner = MockUserVerificationRunner()
        subject = DefaultFido2UserVerificationMediator(
            authRepository: authRepository,
            stateService: stateService,
            userVerificationHelper: userVerificationHelper,
            userVerificationRunner: userVerificationRunner
        )
        subject.setupDelegate(fido2UserVerificationMediatorDelegate: fido2UserVerificationMediatorDelegate)
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        errorReporter = nil
        fido2UserVerificationMediatorDelegate = nil
        stateService = nil
        userVerificationHelper = nil
        userVerificationRunner = nil
        subject = nil
    }

    // MARK: Tests

    /// `checkUser(userVerificationPreference:credential:)`  with each preference,
    /// reprompt enabled and reprompt verified.
    func test_checkUser_anyPreferenceVerifiedReprompt() async throws {
        try await checkUser_verified_when_reprompt_and_reprompt_verified(.discouraged)
        try await checkUser_verified_when_reprompt_and_reprompt_verified(.preferred)
        try await checkUser_verified_when_reprompt_and_reprompt_verified(.required)
    }

    /// `checkUser(userVerificationPreference:credential:)`  with each preference,
    /// reprompt enabled and reprompt not verified.
    func test_checkUser_anyPreferenceNotVerifiedReprompt() async throws {
        try await checkUser_not_verified_when_reprompt_and_reprompt_not_verified(.discouraged)
        try await checkUser_not_verified_when_reprompt_and_reprompt_not_verified(.preferred)
        try await checkUser_not_verified_when_reprompt_and_reprompt_not_verified(.required)
    }

    /// `checkUser(userVerificationPreference:credential:)`  with each preference,
    /// reprompt enabled and reprompt throws.
    func test_checkUser_anyPreferenceThrowsReprompt() async throws {
        try await checkUser_throws_when_reprompt_and_reprompt_throws(.discouraged)
        try await checkUser_throws_when_reprompt_and_reprompt_throws(.preferred)
        try await checkUser_throws_when_reprompt_and_reprompt_throws(.required)
    }

    /// `checkUser(userVerificationPreference:credential:)`  with each preference,
    /// reprompt enabled and needs user interaction.
    func test_checkUser_anyPreferenceRepromptThrowsNeedsUserInteraction() async throws {
        try await checkUser_throws_when_repromptNeedsUserInteraction(.discouraged)
        try await checkUser_throws_when_repromptNeedsUserInteraction(.preferred)
        try await checkUser_throws_when_repromptNeedsUserInteraction(.required)
    }

    /// `checkUser(userVerificationPreference:credential:)`  with each preference,
    /// account has been unlocked in current transaction.
    func test_checkUser_anyPreferenceUnlockedCurrentTransaction() async throws {
        try await checkUser_verified_when_unlockedCurrentTransation(.discouraged)
        try await checkUser_verified_when_unlockedCurrentTransation(.preferred)
        try await checkUser_verified_when_unlockedCurrentTransation(.required)
    }

    /// `checkUser(userVerificationPreference:credential:)`  with each preference,
    /// account has not been unlocked in current transaction but throws becuase needs user interaction.
    func test_checkUser_anyPreferenceThrowsNeedsUserInteraction() async throws {
        try await checkUser_throws_when_needsUserInteraction(.discouraged)
        try await checkUser_throws_when_needsUserInteraction(.preferred)
        try await checkUser_throws_when_needsUserInteraction(.required)
    }

    /// `checkUser(userVerificationPreference:credential:)`  with preference discouraged,
    /// reprompt none.
    func test_checkUser_discouragedNotVerified() async throws {
        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(userVerificationPreference: .discouraged, credential: cipher)

        XCTAssertEqual(result, CheckUserResult(userPresent: true, userVerified: false))
    }

    /// `checkUser(userVerificationPreference:credential:)`  with preference preferred,
    /// reprompt none and verified device local auth.
    func test_checkUser_preferredVerifiedDevice() async throws {
        userVerificationHelper.verifyDeviceLocalAuthResult = .success(.verified)

        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(userVerificationPreference: .preferred, credential: cipher)

        XCTAssertEqual(result, CheckUserResult(userPresent: true, userVerified: true))
        XCTAssertEqual(
            userVerificationHelper.verifyDeviceLocalAuthBecauseValue,
            Localizations.userVerificationForPasskey
        )
    }

    /// `checkUser(userVerificationPreference:credential:)`  with preference preferred,
    /// reprompt none and not verified device local auth.
    func test_checkUser_preferredNotVerifiedDevice() async throws {
        userVerificationHelper.verifyDeviceLocalAuthResult = .success(.notVerified)

        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(userVerificationPreference: .preferred, credential: cipher)

        XCTAssertEqual(result, CheckUserResult(userPresent: true, userVerified: false))
        XCTAssertEqual(
            userVerificationHelper.verifyDeviceLocalAuthBecauseValue,
            Localizations.userVerificationForPasskey
        )
    }

    /// `checkUser(userVerificationPreference:credential:)`  with preference required,
    /// reprompt none and verified flow.
    func test_checkUser_requiredVerified() async throws {
        userVerificationRunner.verifyInQueueResult = .success(.verified)

        setup_checkUser_onVerifyFunctions()

        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(userVerificationPreference: .required, credential: cipher)

        XCTAssertTrue(userVerificationRunner.verifyInQueueCalled)
        XCTAssertTrue(userVerificationRunner.verifyWithAttemptsTimesCalled == 2)
        XCTAssertEqual(result, CheckUserResult(userPresent: true, userVerified: true))
        XCTAssertEqual(
            userVerificationHelper.verifyDeviceLocalAuthBecauseValue,
            Localizations.userVerificationForPasskey
        )
    }

    /// `checkUser(userVerificationPreference:credential:)`  with preference required,
    /// reprompt none and not verified flow.
    func test_checkUser_requiredNotVerified() async throws {
        userVerificationRunner.verifyInQueueResult = .success(.notVerified)

        setup_checkUser_onVerifyFunctions()

        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(userVerificationPreference: .required, credential: cipher)

        XCTAssertTrue(userVerificationRunner.verifyInQueueCalled)
        XCTAssertTrue(userVerificationRunner.verifyWithAttemptsTimesCalled == 2)
        XCTAssertEqual(result, CheckUserResult(userPresent: true, userVerified: false))
        XCTAssertEqual(
            userVerificationHelper.verifyDeviceLocalAuthBecauseValue,
            Localizations.userVerificationForPasskey
        )
    }

    /// `checkUser(userVerificationPreference:credential:)`  with preference required,
    /// reprompt none and unable to perform perform device local auth, pin nor master passwrod verifications.
    func test_checkUser_requiredUnableToPerform() async throws {
        userVerificationRunner.verifyInQueueResult = .success(.unableToPerform)

        setup_checkUser_onVerifyFunctions()

        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(userVerificationPreference: .required, credential: cipher)

        XCTAssertTrue(userVerificationRunner.verifyInQueueCalled)
        XCTAssertTrue(userVerificationRunner.verifyWithAttemptsTimesCalled == 2)
        XCTAssertEqual(result, CheckUserResult(userPresent: true, userVerified: true))
        XCTAssertTrue(userVerificationHelper.setupPinCalled)
        XCTAssertEqual(
            userVerificationHelper.verifyDeviceLocalAuthBecauseValue,
            Localizations.userVerificationForPasskey
        )
    }

    /// `isPreferredVerificationEnabled)`  succeeds because user has been unlocked in the current transaction.
    func test_isPreferredVerificationEnabled_successUnlockedCurrentSession() async throws {
        stateService.getAccountHasBeenUnlockedInteractivelyResult = .success(true)
        let result = await subject.isPreferredVerificationEnabled()
        XCTAssertTrue(result)
    }

    /// `isPreferredVerificationEnabled)`  succeeds because user not has been unlocked in the current transaction
    /// but can verify device local authentication
    func test_isPreferredVerificationEnabled_successCanVerifyDeviceLocalAuth() async throws {
        stateService.getAccountHasBeenUnlockedInteractivelyResult = .success(false)
        userVerificationHelper.canVerifyDeviceLocalAuthResult = true
        let result = await subject.isPreferredVerificationEnabled()
        XCTAssertTrue(result)
    }

    /// `isPreferredVerificationEnabled)`  succeeds because throws error when checking if user has been unlocked
    /// in the current transaction but can verify device local authentication
    func test_isPreferredVerificationEnabled_successCanVerifyDeviceErrorUnlockedCurrentSession() async throws {
        stateService.getAccountHasBeenUnlockedInteractivelyResult = .failure(BitwardenTestError.example)
        userVerificationHelper.canVerifyDeviceLocalAuthResult = true
        let result = await subject.isPreferredVerificationEnabled()
        XCTAssertTrue(result)
    }

    /// `isPreferredVerificationEnabled)`  isn't enabled because user has not been unlocked in the current transaction
    /// nor can verify device local authentication.
    func test_isPreferredVerificationEnabled_unlockedCurrentTransaction() async throws {
        userVerificationHelper.canVerifyDeviceLocalAuthResult = false
        stateService.getAccountHasBeenUnlockedInteractivelyResult = .success(false)

        let result = await subject.isPreferredVerificationEnabled()
        XCTAssertFalse(result)
    }

    // MARK: Private

    @MainActor
    private func checkUser_verified_when_reprompt_and_reprompt_verified(
        _ userVerificationPreference: BitwardenSdk.Verification,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        authRepository.canVerifyMasterPasswordResult = .success(true)
        userVerificationHelper.verifyMasterPasswordResult = .success(.verified)

        let cipher = CipherView.fixture(reprompt: .password)
        let result = try await subject.checkUser(
            userVerificationPreference: userVerificationPreference,
            credential: cipher
        )

        XCTAssertEqual(
            result,
            CheckUserResult(userPresent: true, userVerified: true),
            "Failed for preference \(userVerificationPreference)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            fido2UserVerificationMediatorDelegate.onNeedsUserInteractionCalled,
            file: file,
            line: line
        )
    }

    @MainActor
    private func checkUser_not_verified_when_reprompt_and_reprompt_not_verified(
        _ userVerificationPreference: BitwardenSdk.Verification,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        authRepository.canVerifyMasterPasswordResult = .success(true)
        userVerificationHelper.verifyMasterPasswordResult = .success(.notVerified)

        let cipher = CipherView.fixture(reprompt: .password)
        await assertAsyncThrows(
            error: Fido2UserVerificationError.masterPasswordRepromptFailed,
            file: file,
            line: line
        ) {
            _ = try await subject.checkUser(
                userVerificationPreference: userVerificationPreference,
                credential: cipher
            )
        }
        XCTAssertTrue(
            fido2UserVerificationMediatorDelegate.onNeedsUserInteractionCalled,
            file: file,
            line: line
        )
    }

    @MainActor
    private func checkUser_throws_when_reprompt_and_reprompt_throws(
        _ userVerificationPreference: BitwardenSdk.Verification,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        authRepository.canVerifyMasterPasswordResult = .success(true)
        userVerificationHelper.verifyMasterPasswordResult = .failure(BitwardenTestError.example)

        let cipher = CipherView.fixture(reprompt: .password)

        await assertAsyncThrows(error: BitwardenTestError.example, file: file, line: line) {
            _ = try await subject.checkUser(
                userVerificationPreference: userVerificationPreference,
                credential: cipher
            )
        }
        XCTAssertTrue(
            fido2UserVerificationMediatorDelegate.onNeedsUserInteractionCalled,
            file: file,
            line: line
        )
    }

    @MainActor
    private func checkUser_throws_when_repromptNeedsUserInteraction(
        _ userVerificationPreference: BitwardenSdk.Verification,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        fido2UserVerificationMediatorDelegate.onNeedsUserInteractionError = BitwardenTestError.example

        let cipher = CipherView.fixture(reprompt: .password)

        await assertAsyncThrows(error: BitwardenTestError.example, file: file, line: line) {
            _ = try await subject.checkUser(
                userVerificationPreference: userVerificationPreference,
                credential: cipher
            )
        }
        XCTAssertTrue(
            fido2UserVerificationMediatorDelegate.onNeedsUserInteractionCalled,
            file: file,
            line: line
        )
    }

    @MainActor
    private func checkUser_throws_when_needsUserInteraction(
        _ userVerificationPreference: BitwardenSdk.Verification,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        fido2UserVerificationMediatorDelegate.onNeedsUserInteractionError = BitwardenTestError.example

        let cipher = CipherView.fixture()

        await assertAsyncThrows(error: BitwardenTestError.example, file: file, line: line) {
            _ = try await subject.checkUser(
                userVerificationPreference: userVerificationPreference,
                credential: cipher
            )
        }
        XCTAssertTrue(
            fido2UserVerificationMediatorDelegate.onNeedsUserInteractionCalled,
            file: file,
            line: line
        )
    }

    private func checkUser_verified_when_unlockedCurrentTransation(
        _ userVerificationPreference: BitwardenSdk.Verification,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        stateService.getAccountHasBeenUnlockedInteractivelyResult = .success(true)
        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(
            userVerificationPreference: userVerificationPreference,
            credential: cipher
        )

        XCTAssertEqual(
            result,
            CheckUserResult(userPresent: true, userVerified: true),
            "Failed for preference \(userVerificationPreference)",
            file: file,
            line: line
        )
    }

    private func setup_checkUser_onVerifyFunctions() {
        userVerificationRunner.onVerifyInQueueFunctionCalled = { index in
            switch index {
            case 0:
                XCTAssertTrue(self.userVerificationHelper.verifyDeviceLocalAuthCalled)
                XCTAssertFalse(self.userVerificationHelper.verifyPinCalled)
                XCTAssertFalse(self.userVerificationHelper.verifyMasterPasswordCalled)
            case 1:
                XCTAssertTrue(self.userVerificationHelper.verifyDeviceLocalAuthCalled)
                XCTAssertTrue(self.userVerificationHelper.verifyPinCalled)
                XCTAssertFalse(self.userVerificationHelper.verifyMasterPasswordCalled)
            case 2:
                XCTAssertTrue(self.userVerificationHelper.verifyDeviceLocalAuthCalled)
                XCTAssertTrue(self.userVerificationHelper.verifyPinCalled)
                XCTAssertTrue(self.userVerificationHelper.verifyMasterPasswordCalled)
            default:
                XCTFail("Failed because there are more verify functions than expected")
            }
        }

        userVerificationRunner.onverifyWithAttemptsFunctionCalled = { timesCalled in
            switch timesCalled {
            case 1:
                XCTAssertTrue(self.userVerificationHelper.verifyPinCalled)
                XCTAssertFalse(self.userVerificationHelper.verifyMasterPasswordCalled)
            case 2:
                XCTAssertTrue(self.userVerificationHelper.verifyPinCalled)
                XCTAssertTrue(self.userVerificationHelper.verifyMasterPasswordCalled)
            default:
                XCTFail("Failed because verify with attempts was called more than expected")
            }
        }
    }
}

class MockFido2UserVerificationMediatorDelegate:
    MockUserVerificationHelperDelegate,
    Fido2UserVerificationMediatorDelegate {
    var onNeedsUserInteractionCalled = false
    var onNeedsUserInteractionError: Error?

    func onNeedsUserInteraction() async throws {
        onNeedsUserInteractionCalled = true
        if let onNeedsUserInteractionError {
            throw onNeedsUserInteractionError
        }
    }
} // swiftlint:disable:this file_length
