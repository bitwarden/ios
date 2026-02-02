import BitwardenKit
import BitwardenKitMocks
import LocalAuthentication
import TestHelpers
import XCTest

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
        biometricsService.getBiometricAuthStatusReturnValue = .notDetermined
        biometricsService.evaluateBiometricPolicyReturnValue = true
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
        biometricsService.getBiometricAuthenticationTypeReturnValue = .faceID
        XCTAssertEqual(subject.getBiometricAuthenticationType(), .faceID)

        biometricsService.getBiometricAuthenticationTypeReturnValue = nil
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
        biometricsService.getBiometricAuthStatusReturnValue = .lockedOut(.faceID)
        stateService.getBiometricAuthenticationEnabledActiveAccount = false
        await assertAsyncThrows(error: BiometricsServiceError.biometryLocked) {
            _ = try await subject.getBiometricUnlockStatus()
        }
    }

    /// `getBiometricUnlockStatus` tracks the availability of biometrics.
    func test_getBiometricUnlockStatus_success_denied() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.getBiometricAuthenticationEnabledActiveAccount = false
        biometricsService.getBiometricAuthStatusReturnValue = .denied(.touchID)
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            .notAvailable,
        )
    }

    /// `getBiometricUnlockStatus` tracks if a user has enabled or disabled biometrics.
    func test_getBiometricUnlockStatus_success_disabled() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.getBiometricAuthenticationEnabledActiveAccount = false
        biometricsService.getBiometricAuthStatusReturnValue = .authorized(.touchID)
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            BiometricsUnlockStatus.available(.touchID, enabled: false),
        )
    }

    /// `getBiometricUnlockStatus` tracks all biometrics components.
    func test_getBiometricUnlockStatus_success() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.getBiometricAuthenticationEnabledActiveAccount = true
        biometricsService.getBiometricAuthStatusReturnValue = .authorized(.faceID)
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            BiometricsUnlockStatus.available(.faceID, enabled: true),
        )
    }

    /// `getBiometricUnlockStatus` with a specific userId checks the status for that user.
    func test_getBiometricUnlockStatus_withSpecificUserId() async throws {
        stateService.activeAccountIdResult = .success("1")
        biometricsService.getBiometricAuthStatusReturnValue = .authorized(.faceID)
        stateService.getBiometricAuthenticationEnabledByUserId["specificUser"] = true

        let status = try await subject.getBiometricUnlockStatus(userId: "specificUser")
        XCTAssertEqual(status, .available(.faceID, enabled: true))
    }

    /// `getUserAuthKey` throws on empty keys.
    func test_getUserAuthKey_emptyString() async throws {
        stateService.activeAccountIdResult = .success("1")
        keychainService.getUserBiometricAuthKeyReturnValue = ""
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` retrieves the key from keychain.
    func test_getUserAuthKey_success() async throws {
        stateService.activeAccountIdResult = .success("1")
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
        // -8 is the code for kLAErrorBiometryLockout.
        keychainService.getUserBiometricAuthKeyThrowableError = KeychainServiceError.osStatusError(-8)
        await assertAsyncThrows(error: BiometricsServiceError.biometryLocked) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws a not found error if the key can't be found.
    func test_getUserAuthKey_notFoundError() async throws {
        stateService.activeAccountIdResult = .success("1")
        keychainService.getUserBiometricAuthKeyThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws a biometry failed error if biometrics are disconnected.
    func test_getUserAuthKey_biometryFailed() async throws {
        stateService.activeAccountIdResult = .success("1")
        let error = KeychainServiceError.osStatusError(kLAErrorBiometryDisconnected)
        keychainService.getUserBiometricAuthKeyThrowableError = error
        await assertAsyncThrows(error: BiometricsServiceError.biometryFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws a biometry cancelled error if biometrics were cancelled.
    func test_getUserAuthKey_cancelled() async throws {
        stateService.activeAccountIdResult = .success("1")
        let error = KeychainServiceError.osStatusError(errSecUserCanceled)
        keychainService.getUserBiometricAuthKeyThrowableError = error
        await assertAsyncThrows(error: BiometricsServiceError.biometryCancelled) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws an error if one occurs.
    func test_getUserAuthKey_unknownError() async throws {
        stateService.activeAccountIdResult = .success("1")
        keychainService.getUserBiometricAuthKeyThrowableError = BitwardenTestError.example
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws an error if an unknown OS error occurs.
    func test_getUserAuthKey_unknownOSError() async throws {
        stateService.activeAccountIdResult = .success("1")
        let error = KeychainServiceError.osStatusError(errSecParam)
        keychainService.getUserBiometricAuthKeyThrowableError = error
        await assertAsyncThrows(error: KeychainServiceError.osStatusError(errSecParam)) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `setBiometricUnlockKey` throws when there is no active account.
    func test_setBiometricUnlockKey_nilValue_noActiveAccount() async throws {
        stateService.activeAccountIdError = BitwardenTestError.mock("NoActiveAccount")
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
        stateService.getBiometricAuthenticationEnabledActiveAccount = true
        biometricsService.evaluateBiometricPolicyReturnValue = false
        try await subject.setBiometricUnlockKey(authKey: "1234")
        waitFor(keychainService.deleteUserBiometricAuthKeyCalled)
        XCTAssertFalse(keychainService.setUserBiometricAuthKeyCalled)
        XCTAssertEqual(stateService.setBiometricAuthenticationEnabledByUserId["1"], false)
    }

    /// `setBiometricUnlockKey` can remove a user key from the keychain and track the availability in state.
    func test_setBiometricUnlockKey_nilValue_success() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.getBiometricAuthenticationEnabledActiveAccount = true
        try await subject.setBiometricUnlockKey(authKey: nil)
        waitFor(keychainService.deleteUserBiometricAuthKeyCalled)
        XCTAssertFalse(keychainService.setUserBiometricAuthKeyCalled)
        XCTAssertEqual(stateService.setBiometricAuthenticationEnabledByUserId["1"], false)
    }

    /// `setBiometricUnlockKey` throws on a keychain error.
    func test_setBiometricUnlockKey_nilValue_successWithKeychainError() async throws {
        stateService.activeAccountIdResult = .success("1")
        stateService.getBiometricAuthenticationEnabledActiveAccount = true
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
        biometricsService.evaluateBiometricPolicyReturnValue = true
        stateService.activeAccountIdResult = .success("1")
        stateService.getBiometricAuthenticationEnabledByUserId["1"] = false
        keychainService.setUserBiometricAuthKeyThrowableError = KeychainServiceError.osStatusError(13)
        await assertAsyncThrows(
            error: BiometricsServiceError.setAuthKeyFailed,
        ) {
            try await subject.setBiometricUnlockKey(authKey: "authKey")
        }
    }

    /// `setBiometricUnlockKey` can store a user key to the keychain and track the availability in state.
    func test_setBiometricUnlockKey_withValue_success() async throws {
        biometricsService.evaluateBiometricPolicyReturnValue = true
        stateService.activeAccountIdResult = .success("1")
        stateService.getBiometricAuthenticationEnabledActiveAccount = false
        try await subject.setBiometricUnlockKey(authKey: "authKey")
        waitFor(keychainService.setUserBiometricAuthKeyCalled)
        XCTAssertEqual("authKey", keychainService.setUserBiometricAuthKeyReceivedArguments?.value)
        XCTAssertEqual("1", keychainService.setUserBiometricAuthKeyReceivedArguments?.userId)
        XCTAssertEqual(stateService.setBiometricAuthenticationEnabledByUserId["1"], true)
    }

    /// `setBiometricUnlockKey` with a specific userId clears biometrics for that user, not the active user.
    func test_setBiometricUnlockKey_withSpecificUserId_clearsCorrectUser() async throws {
        stateService.activeAccountIdResult = .success("activeUser")
        stateService.getBiometricAuthenticationEnabledByUserId["inactiveUser"] = true

        try await subject.setBiometricUnlockKey(authKey: nil, userId: "inactiveUser")

        waitFor(keychainService.deleteUserBiometricAuthKeyCalled)
        XCTAssertEqual("inactiveUser", keychainService.deleteUserBiometricAuthKeyReceivedUserId)
        XCTAssertEqual(stateService.setBiometricAuthenticationEnabledByUserId["inactiveUser"], false)
    }

    /// `setBiometricUnlockKey` with a specific userId sets biometrics for that user.
    func test_setBiometricUnlockKey_withSpecificUserId_setsCorrectUser() async throws {
        biometricsService.evaluateBiometricPolicyReturnValue = true
        stateService.activeAccountIdResult = .success("activeUser")
        stateService.getBiometricAuthenticationEnabledByUserId["inactiveUser"] = false

        try await subject.setBiometricUnlockKey(authKey: "authKey", userId: "inactiveUser")

        waitFor(keychainService.setUserBiometricAuthKeyCalled)
        XCTAssertEqual("authKey", keychainService.setUserBiometricAuthKeyReceivedArguments?.value)
        XCTAssertEqual("inactiveUser", keychainService.setUserBiometricAuthKeyReceivedArguments?.userId)
        XCTAssertEqual(stateService.setBiometricAuthenticationEnabledByUserId["inactiveUser"], true)
    }
}
