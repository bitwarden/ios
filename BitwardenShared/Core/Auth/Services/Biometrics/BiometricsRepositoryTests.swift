import BitwardenKit
import BitwardenKitMocks
import LocalAuthentication
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BiometricsRepositoryTests

final class BiometricsRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var biometricsService: MockBiometricsService!
    var keychainService: MockBiometricsKeychainRepository!
    var stateService: MockBiometricsStateService!
    var subject: DefaultBiometricsRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        biometricsService = MockBiometricsService()
        keychainService = MockBiometricsKeychainRepository()
        stateService = MockBiometricsStateService()

        subject = DefaultBiometricsRepository(
            biometricsService: biometricsService,
            keychainService: keychainService,
            stateService: stateService,
        )
    }

    override func tearDown() {
        super.tearDown()

        biometricsService = nil
        keychainService = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `getBiometricAuthenticationType()` gets the current authentication type.
    func test_getBiometricAuthenticationType() async throws {
        biometricsService.biometricAuthenticationType = .faceID
        XCTAssertEqual(subject.getBiometricAuthenticationType(), .faceID)

        biometricsService.biometricAuthenticationType = nil
        XCTAssertNil(subject.getBiometricAuthenticationType())
    }

    /// `setBiometricUnlockKey` throws for a no-user situation.
    func test_getBiometricUnlockKey_noActiveAccount() async throws {
        stateService.activeAccountIdResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `setBiometricUnlockKey` throws for a keychain error.
    func test_getBiometricUnlockKey_keychainServiceError() async throws {
        stateService.activeAccountIdResult = .success("1")
        let mockKey = MockKeychainStorageKeyPossessing(unformattedKey: "Mock Key Biometrics: User ID 1")
        let error = KeychainServiceError.keyNotFound(mockKey)
        keychainService.getUserBiometricAuthKeyThrowableError = error
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `setBiometricUnlockKey` throws an error for an empty key.
    func test_getBiometricUnlockKey_emptyString() async throws {
        let expectedKey = ""
        stateService.activeAccountIdResult = .success("1")
        keychainService.getUserBiometricAuthKeyReturnValue = expectedKey
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `setBiometricUnlockKey` returns the correct key for the active user.
    func test_getBiometricUnlockKey_success() async throws {
        let expectedKey = "expectedKey"
        stateService.activeAccountIdResult = .success("1")
        keychainService.getUserBiometricAuthKeyReturnValue = expectedKey
        let key = try await subject.getUserAuthKey()
        XCTAssertEqual(key, expectedKey)
    }

    /// `setBiometricUnlockKey` throws a cancelled error for `errSecAuthFailed` if the device is
    /// locked while performing biometrics.
    func test_getBiometricUnlockKey_authFailed() async throws {
        stateService.activeAccountIdResult = .success("1")
        keychainService.getUserBiometricAuthKeyThrowableError = KeychainServiceError.osStatusError(errSecAuthFailed)
        await assertAsyncThrows(error: BiometricsServiceError.biometryCancelled) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getBiometricUnlockStatus` throws an error if the user has locked biometrics.
    func test_getBiometricUnlockStatus_lockout() async throws {
        stateService.activeAccountIdResult = .success("1")
        biometricsService.biometricAuthStatus = .lockedOut(.faceID)
        stateService.biometricAuthenticationEnabledResult = .success(false)
        await assertAsyncThrows(error: BiometricsServiceError.biometryLocked) {
            _ = try await subject.getBiometricUnlockStatus()
        }
    }

    /// `getBiometricUnlockStatus` tracks the availability of biometrics.
    func test_getBiometricUnlockStatus_success_denied() async throws {
        stateService.activeAccountIdResult = .success("1")
        biometricsService.biometricAuthStatus = .denied(.touchID)
        stateService.biometricAuthenticationEnabledResult = .success(false)
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            .notAvailable,
        )
    }

    /// `getBiometricUnlockStatus` tracks if a user has enabled or disabled biometrics.
    func test_getBiometricUnlockStatus_success_disabled() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(false)
        biometricsService.biometricAuthStatus = .authorized(.touchID)
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            BiometricsUnlockStatus.available(.touchID, enabled: false),
        )
    }

    /// `getBiometricUnlockStatus` tracks all biometrics components.
    func test_getBiometricUnlockStatus_success() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(true)
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            BiometricsUnlockStatus.available(.faceID, enabled: true),
        )
    }

    /// `getUserAuthKey` throws on empty keys.
    func test_getUserAuthKey_emptyString() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(true)
        keychainService.getUserBiometricAuthKeyReturnValue = ""
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` retrieves the key from keychain.
    func test_getUserAuthKey_success() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(true)
        keychainService.getUserBiometricAuthKeyReturnValue = "Dramatic Masterpiece"
        let key = try await subject.getUserAuthKey()
        XCTAssertEqual(
            key,
            "Dramatic Masterpiece",
        )
    }

    /// `getUserAuthKey` throws a biometry locked error if biometrics are locked out.
    func test_getUserAuthKey_lockedError() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(true)
        // -8 is the code for kLAErrorBiometryLockout.
        keychainService.getUserBiometricAuthKeyThrowableError = KeychainServiceError.osStatusError(-8)
        await assertAsyncThrows(error: BiometricsServiceError.biometryLocked) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws a not found error if the key can't be found.
    func test_getUserAuthKey_notFoundError() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(true)
        keychainService.getUserBiometricAuthKeyThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws a biometry failed error if biometrics are disconnected.
    func test_getUserAuthKey_biometryFailed() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(true)
        let error = KeychainServiceError.osStatusError(kLAErrorBiometryDisconnected)
        keychainService.getUserBiometricAuthKeyThrowableError = error
        await assertAsyncThrows(error: BiometricsServiceError.biometryFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws a biometry cancelled error if biometrics were cancelled.
    func test_getUserAuthKey_cancelled() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(true)
        let error = KeychainServiceError.osStatusError(errSecUserCanceled)
        keychainService.getUserBiometricAuthKeyThrowableError = error
        await assertAsyncThrows(error: BiometricsServiceError.biometryCancelled) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws an error if one occurs.
    func test_getUserAuthKey_unknownError() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(true)
        keychainService.getUserBiometricAuthKeyThrowableError = BitwardenTestError.example
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws an error if an unknown OS error occurs.
    func test_getUserAuthKey_unknownOSError() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(true)
        let error = KeychainServiceError.osStatusError(errSecParam)
        keychainService.getUserBiometricAuthKeyThrowableError = error
        await assertAsyncThrows(error: KeychainServiceError.osStatusError(errSecParam)) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `setBiometricUnlockKey` throws when there is no active account.
    func test_setBiometricUnlockKey_nilValue_noActiveAccount() async throws {
        stateService.setBiometricAuthenticationEnabledError = BitwardenTestError.mock("NoActiveAccount")
        await assertAsyncThrows(error: BitwardenTestError.mock("NoActiveAccount")) {
            try await subject.setBiometricUnlockKey(authKey: nil)
        }
    }

    /// `setBiometricUnlockKey` throws when there is a state service error.
    func test_setBiometricUnlockKey_nilValue_setBiometricAuthenticationEnabledFailed() async throws {
        stateService.activeAccountIdResult = .success("1")
        let error = BitwardenTestError.mock("setBiometricAuthenticationEnabledFailed")
        stateService.setBiometricAuthenticationEnabledError = error
        await assertAsyncThrows(
            error: BitwardenTestError.mock("setBiometricAuthenticationEnabledFailed"),
        ) {
            try await subject.setBiometricUnlockKey(authKey: nil)
        }
    }

    /// `setBiometricUnlockKey` A failure in evaluating the biometrics policy clears any auth key.
    func test_setBiometricUnlockKey_evaluationFalse() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(true)
        biometricsService.evaluationResult = false
        try await subject.setBiometricUnlockKey(authKey: "1234")
        waitFor(keychainService.deleteUserBiometricAuthKeyCalled)
        XCTAssertFalse(keychainService.setUserBiometricAuthKeyCalled)
        let result = try stateService.biometricAuthenticationEnabledResult.get()
        XCTAssertFalse(result)
    }

    /// `setBiometricUnlockKey` can remove a user key from the keychain and track the availability in state.
    func test_setBiometricUnlockKey_nilValue_success() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(true)
        try await subject.setBiometricUnlockKey(authKey: nil)
        waitFor(keychainService.deleteUserBiometricAuthKeyCalled)
        let result = try stateService.biometricAuthenticationEnabledResult.get()
        XCTAssertFalse(result)
    }

    /// `setBiometricUnlockKey` throws on a keychain error.
    func test_setBiometricUnlockKey_nilValue_successWithKeychainError() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(true)
        keychainService.setUserBiometricAuthKeyThrowableError = KeychainServiceError.osStatusError(13)
        await assertAsyncDoesNotThrow {
            try await subject.setBiometricUnlockKey(authKey: nil)
        }
    }

    /// `setBiometricUnlockKey` throws when there is no active account.
    func test_setBiometricUnlockKey_withValue_noActiveAccount() async throws {
        stateService.activeAccountIdError = BitwardenTestError.mock("NoActiveAccount")
        await assertAsyncThrows(error: BitwardenTestError.mock("NoActiveAccount")) {
            try await subject.setBiometricUnlockKey(authKey: "authKey")
        }
    }

    /// `setBiometricUnlockKey` throws when there is no active account.
    func test_setBiometricUnlockKey_withValue_setBiometricAuthenticationEnabledFailed() async throws {
        stateService.activeAccountIdResult = .success("1")
        let error = BitwardenTestError.mock("setBiometricAuthenticationEnabledFailed")
        stateService.setBiometricAuthenticationEnabledError = error
        await assertAsyncThrows(
            error: BitwardenTestError.mock("setBiometricAuthenticationEnabledFailed"),
        ) {
            try await subject.setBiometricUnlockKey(authKey: "authKey")
        }
    }

    /// `setBiometricUnlockKey` throws on a keychain error.
    func test_setBiometricUnlockKey_withValue_keychainError() async throws {
        biometricsService.evaluationResult = true
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(false)
        keychainService.setUserBiometricAuthKeyThrowableError = KeychainServiceError.osStatusError(13)
        await assertAsyncThrows(
            error: BiometricsServiceError.setAuthKeyFailed,
        ) {
            try await subject.setBiometricUnlockKey(authKey: "authKey")
        }
    }

    /// `setBiometricUnlockKey` can store a user key to the keychain and track the availability in state.
    func test_setBiometricUnlockKey_withValue_success() async throws {
        biometricsService.evaluationResult = true
        stateService.activeAccountIdResult = .success("1")
        stateService.biometricAuthenticationEnabledResult = .success(false)
        try await subject.setBiometricUnlockKey(authKey: "authKey")
        waitFor(keychainService.setUserBiometricAuthKeyCalled)
        XCTAssertEqual("authKey", keychainService.setUserBiometricAuthKeyReceivedArguments?.value)
        XCTAssertEqual("1", keychainService.setUserBiometricAuthKeyReceivedArguments?.userId)
        let result = try stateService.biometricAuthenticationEnabledResult.get()
        XCTAssertTrue(result)
    }
}
