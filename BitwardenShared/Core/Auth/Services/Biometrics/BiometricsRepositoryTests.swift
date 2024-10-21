import LocalAuthentication
import XCTest

@testable import BitwardenShared

// MARK: - BiometricsRepositoryTests

final class BiometricsRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Types

    enum TestError: Error, Equatable {
        case mock(String)
    }

    // MARK: Properties

    var biometricsService: MockBiometricsService!
    var keychainService: MockKeychainRepository!
    var stateService: MockStateService!
    var subject: DefaultBiometricsRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        biometricsService = MockBiometricsService()
        keychainService = MockKeychainRepository()
        stateService = MockStateService()

        subject = DefaultBiometricsRepository(
            biometricsService: biometricsService,
            keychainService: keychainService,
            stateService: stateService
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

    /// `setBiometricUnlockKey` throws for a no user situation.
    func test_getBiometricUnlockKey_noActiveAccount() async throws {
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `setBiometricUnlockKey` throws for a keychain error.
    func test_getBiometricUnlockKey_keychainServiceError() async throws {
        stateService.activeAccount = .fixture()
        keychainService.getResult = .failure(
            KeychainServiceError.keyNotFound(.biometrics(userId: "1"))
        )
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `setBiometricUnlockKey` throws an error for an empty key.
    func test_getBiometricUnlockKey_emptyString() async throws {
        let expectedKey = ""
        stateService.activeAccount = .fixture()
        keychainService.getResult = .success(expectedKey)
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `setBiometricUnlockKey` returns the correct key for the active user.
    func test_getBiometricUnlockKey_success() async throws {
        let expectedKey = "expectedKey"
        stateService.activeAccount = .fixture()
        keychainService.getResult = .success(expectedKey)
        let key = try await subject.getUserAuthKey()
        XCTAssertEqual(key, expectedKey)
    }

    /// `setBiometricUnlockKey` throws a cancelled error for `errSecAuthFailed` if the device is
    /// locked while performing biometrics.
    func test_getBiometricUnlockKey_authFailed() async throws {
        stateService.activeAccount = .fixture()
        keychainService.getResult = .failure(
            KeychainServiceError.osStatusError(errSecAuthFailed)
        )
        await assertAsyncThrows(error: BiometricsServiceError.biometryCancelled) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getBiometricUnlockStatus` throws an error if the user has locked biometrics.
    func test_getBiometricUnlockStatus_lockout() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        biometricsService.biometricAuthStatus = .lockedOut(.faceID)
        stateService.biometricsEnabled = [
            active.profile.userId: false,
        ]
        await assertAsyncThrows(error: BiometricsServiceError.biometryLocked) {
            _ = try await subject.getBiometricUnlockStatus()
        }
    }

    /// `getBiometricUnlockStatus` tracks the availability of biometrics.
    func test_getBiometricUnlockStatus_success_denied() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        biometricsService.biometricAuthStatus = .denied(.touchID)
        stateService.biometricsEnabled = [
            active.profile.userId: false,
        ]
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            .notAvailable
        )
    }

    /// `getBiometricUnlockStatus` tracks if a user has enabled or disabled biometrics.
    func test_getBiometricUnlockStatus_success_disabled() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        biometricsService.biometricAuthStatus = .authorized(.touchID)
        stateService.biometricsEnabled = [
            active.profile.userId: false,
        ]
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            BiometricsUnlockStatus.available(.touchID, enabled: false)
        )
    }

    /// `getBiometricUnlockStatus` tracks all biometrics components.
    func test_getBiometricUnlockStatus_success() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            BiometricsUnlockStatus.available(.faceID, enabled: true)
        )
    }

    /// `getUserAuthKey` throws on empty keys.
    func test_getUserAuthKey_emptyString() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        keychainService.getResult = .success("")
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` retrieves the key from keychain.
    func test_getUserAuthKey_success() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        keychainService.getResult = .success("Dramatic Masterpiece")
        let key = try await subject.getUserAuthKey()
        XCTAssertEqual(
            key,
            "Dramatic Masterpiece"
        )
    }

    /// `getUserAuthKey` throws a biometry locked error if biometrics are locked out.
    func test_getUserAuthKey_lockedError() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        // -8 is the code for kLAErrorBiometryLockout.
        keychainService.getResult = .failure(KeychainServiceError.osStatusError(-8))
        await assertAsyncThrows(error: BiometricsServiceError.biometryLocked) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws a not found error if the key can't be found.
    func test_getUserAuthKey_notFoundError() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        keychainService.getResult = .failure(KeychainServiceError.osStatusError(errSecItemNotFound))
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws a biometry failed error if biometrics are disconnected.
    func test_getUserAuthKey_biometryFailed() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        keychainService.getResult = .failure(KeychainServiceError.osStatusError(kLAErrorBiometryDisconnected))
        await assertAsyncThrows(error: BiometricsServiceError.biometryFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws a biometry cancelled error if biometrics were cancelled.
    func test_getUserAuthKey_cancelled() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        // Send the user cancelled code.
        keychainService.getResult = .failure(KeychainServiceError.osStatusError(errSecUserCanceled))
        await assertAsyncThrows(error: BiometricsServiceError.biometryCancelled) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws an error if one occurs.
    func test_getUserAuthKey_unknownError() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        keychainService.getResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` throws an error if an unknown OS error occurs.
    func test_getUserAuthKey_unknownOSError() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        keychainService.getResult = .failure(KeychainServiceError.osStatusError(errSecParam))
        await assertAsyncThrows(error: KeychainServiceError.osStatusError(errSecParam)) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `setBiometricUnlockKey` throws when there is no active account.
    func test_setBiometricUnlockKey_nilValue_noActiveAccount() async throws {
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.setBiometricUnlockKey(authKey: nil)
        }
    }

    /// `setBiometricUnlockKey` throws when there is a state service error.
    func test_setBiometricUnlockKey_nilValue_setBiometricAuthenticationEnabledFailed() async throws {
        stateService.activeAccount = .fixture()
        stateService.setBiometricAuthenticationEnabledResult = .failure(
            TestError.mock("setBiometricAuthenticationEnabledFailed")
        )
        await assertAsyncThrows(
            error: TestError.mock("setBiometricAuthenticationEnabledFailed")
        ) {
            try await subject.setBiometricUnlockKey(authKey: nil)
        }
    }

    /// `setBiometricUnlockKey` A failure in evaluating the biometrics policy clears any auth key.
    func test_setBiometricUnlockKey_evaluationFalse() async throws {
        stateService.activeAccount = .fixture()
        try? await stateService.setBiometricAuthenticationEnabled(true)
        keychainService.mockStorage = [
            keychainService.formattedKey(for: .biometrics(userId: "1")): "storedKey",
        ]
        biometricsService.evaluationResult = false
        stateService.setBiometricAuthenticationEnabledResult = .success(())
        keychainService.deleteResult = .success(())
        try await subject.setBiometricUnlockKey(authKey: nil)
        waitFor(keychainService.mockStorage.isEmpty)
        let result = try XCTUnwrap(stateService.biometricsEnabled["1"])
        XCTAssertFalse(result)
    }

    /// `setBiometricUnlockKey` can remove a user key from the keychain and track the availability in state.
    func test_setBiometricUnlockKey_nilValue_success() async throws {
        stateService.activeAccount = .fixture()
        try? await stateService.setBiometricAuthenticationEnabled(true)
        keychainService.mockStorage = [
            keychainService.formattedKey(for: .biometrics(userId: "1")): "storedKey",
        ]
        stateService.setBiometricAuthenticationEnabledResult = .success(())
        keychainService.deleteResult = .success(())
        try await subject.setBiometricUnlockKey(authKey: nil)
        waitFor(keychainService.mockStorage.isEmpty)
        let result = try XCTUnwrap(stateService.biometricsEnabled["1"])
        XCTAssertFalse(result)
    }

    /// `setBiometricUnlockKey` throws on a keychain error.
    func test_setBiometricUnlockKey_nilValue_successWithKeychainError() async throws {
        stateService.activeAccount = .fixture()
        stateService.setBiometricAuthenticationEnabledResult = .success(())
        keychainService.deleteResult = .failure(KeychainServiceError.osStatusError(13))
        await assertAsyncDoesNotThrow {
            try await subject.setBiometricUnlockKey(authKey: nil)
        }
    }

    /// `setBiometricUnlockKey` throws when there is no active account.
    func test_setBiometricUnlockKey_withValue_noActiveAccount() async throws {
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.setBiometricUnlockKey(authKey: "authKey")
        }
    }

    /// `setBiometricUnlockKey` throws when there is no active account.
    func test_setBiometricUnlockKey_withValue_setBiometricAuthenticationEnabledFailed() async throws {
        stateService.activeAccount = .fixture()
        stateService.setBiometricAuthenticationEnabledResult = .failure(
            TestError.mock("setBiometricAuthenticationEnabledFailed")
        )
        await assertAsyncThrows(
            error: TestError.mock("setBiometricAuthenticationEnabledFailed")
        ) {
            try await subject.setBiometricUnlockKey(authKey: "authKey")
        }
    }

    /// `setBiometricUnlockKey` throws on a keychain error.
    func test_setBiometricUnlockKey_withValue_keychainError() async throws {
        stateService.activeAccount = .fixture()
        stateService.setBiometricAuthenticationEnabledResult = .success(())
        keychainService.setResult = .failure(KeychainServiceError.osStatusError(13))
        await assertAsyncThrows(
            error: BiometricsServiceError.setAuthKeyFailed
        ) {
            try await subject.setBiometricUnlockKey(authKey: "authKey")
        }
    }

    /// `setBiometricUnlockKey` can store a user key to the keychain and track the availability in state.
    func test_setBiometricUnlockKey_withValue_success() async throws {
        stateService.activeAccount = .fixture()
        stateService.setBiometricAuthenticationEnabledResult = .success(())
        keychainService.setResult = .success(())
        try await subject.setBiometricUnlockKey(authKey: "authKey")
        waitFor(!keychainService.mockStorage.isEmpty)
        XCTAssertEqual(
            "authKey",
            keychainService.mockStorage[keychainService.formattedKey(
                for: .biometrics(
                    userId: "1"
                )
            )]
        )
        let result = try XCTUnwrap(stateService.biometricsEnabled["1"])
        XCTAssertTrue(result)
        XCTAssertEqual(keychainService.securityType, .biometryCurrentSet)
    }
}
