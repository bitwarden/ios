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
    var keychainService: MockKeychainService!
    var stateService: MockStateService!
    var subject: DefaultBiometricsRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        biometricsService = MockBiometricsService()
        keychainService = MockKeychainService()
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

    /// `configureBiometricIntegrity` does not store empty data.
    func test_configureBiometricIntegrity_noData() async throws {
        biometricsService.biometricIntegrityState = nil
        stateService.activeAccount = .fixture()
        stateService.setBiometricIntegrityStateError = nil
        try await subject.configureBiometricIntegrity()
        XCTAssertTrue(stateService.biometricIntegrityStates.isEmpty)
    }

    /// `configureBiometricIntegrity` successfully stores data to state.
    func test_configureBiometricIntegrity_success() async throws {
        let mockData = Data("Mock User Key".utf8)
        let expectedBase64String = mockData.base64EncodedString()
        biometricsService.biometricIntegrityState = mockData
        stateService.activeAccount = .fixture()
        stateService.setBiometricIntegrityStateError = nil
        try await subject.configureBiometricIntegrity()
        XCTAssertEqual(
            stateService.biometricIntegrityStates,
            [
                "1": expectedBase64String,
            ]
        )
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

    /// `getBiometricUnlockStatus` throws an error if the user has locked biometrics.
    func test_getBiometricUnlockStatus_lockout() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        biometricsService.biometricAuthStatus = .lockedOut(.faceID)
        let integrity = Data("Face/Off".utf8)
        biometricsService.biometricIntegrityState = integrity
        stateService.biometricIntegrityStates = [
            active.profile.userId: integrity.base64EncodedString(),
        ]
        stateService.biometricsEnabled = [
            active.profile.userId: false,
        ]
        await assertAsyncThrows(error: BiometricsServiceError.biometryLocked) {
            _ = try await subject.getBiometricUnlockStatus()
        }
    }

    /// `getBiometricUnlockStatus` marks devices without any biometric integrity data as having valid integrity.
    func test_getBiometricUnlockStatus_noDeviceIntegrityData() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        biometricsService.biometricIntegrityState = nil
        stateService.biometricIntegrityStates = [
            active.profile.userId: Data("National Treasure".utf8).base64EncodedString(),
        ]
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            BiometricsUnlockStatus.available(
                .faceID,
                enabled: true,
                hasValidIntegrity: true
            )
        )
    }

    /// `getBiometricUnlockStatus` tracks the availablity of biometrics.
    func test_getBiometricUnlockStatus_success_denied() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        biometricsService.biometricAuthStatus = .denied(.touchID)
        let integrity = Data("Face/Off".utf8)
        biometricsService.biometricIntegrityState = integrity
        stateService.biometricIntegrityStates = [
            active.profile.userId: integrity.base64EncodedString(),
        ]
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
        let integrity = Data("Face/Off".utf8)
        biometricsService.biometricIntegrityState = integrity
        stateService.biometricIntegrityStates = [
            active.profile.userId: integrity.base64EncodedString(),
        ]
        stateService.biometricsEnabled = [
            active.profile.userId: false,
        ]
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            BiometricsUnlockStatus.available(
                .touchID,
                enabled: false,
                hasValidIntegrity: true
            )
        )
    }

    /// `getBiometricUnlockStatus` tracks integrity state validity.
    func test_getBiometricUnlockStatus_success_invalidIntegrity() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        let integrity = Data("Face/Off".utf8)
        biometricsService.biometricIntegrityState = integrity
        stateService.biometricIntegrityStates = [
            active.profile.userId: Data("National Treasure".utf8).base64EncodedString(),
        ]
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            BiometricsUnlockStatus.available(
                .faceID,
                enabled: true,
                hasValidIntegrity: false
            )
        )
    }

    /// `getBiometricUnlockStatus` tracks all biometrics components.
    func test_getBiometricUnlockStatus_success() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        biometricsService.biometricAuthStatus = .authorized(.faceID)
        let integrity = Data("Face/Off".utf8)
        biometricsService.biometricIntegrityState = integrity
        stateService.biometricIntegrityStates = [
            active.profile.userId: integrity.base64EncodedString(),
        ]
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        let status = try await subject.getBiometricUnlockStatus()
        XCTAssertEqual(
            status,
            BiometricsUnlockStatus.available(
                .faceID,
                enabled: true,
                hasValidIntegrity: true
            )
        )
    }

    /// `getUserAuthKey` throws on empty keys.
    func test_getUserAuthKey_emptyString() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        let integrity = Data("Face/Off".utf8)
        biometricsService.biometricIntegrityState = integrity
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        keychainService.getResult = .success("")
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` retrieves the key from keychain and updates integrity state.
    func test_getUserAuthKey_success() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        let integrity = Data("Face/Off".utf8)
        biometricsService.biometricIntegrityState = integrity
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        keychainService.getResult = .success("Dramatic Masterpiece")
        let key = try await subject.getUserAuthKey()
        XCTAssertEqual(
            key,
            "Dramatic Masterpiece"
        )
        XCTAssertEqual(
            stateService.biometricIntegrityStates,
            [
                active.profile.userId: integrity.base64EncodedString(),
            ]
        )
    }

    /// `getUserAuthKey` retrieves the key from keychain and updates integrity state.
    func test_getUserAuthKey_lockedError() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        let integrity = Data("Face/Off".utf8)
        biometricsService.biometricIntegrityState = integrity
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        // -8 is the code for kLAErrorBiometryLockout.
        keychainService.getResult = .failure(KeychainServiceError.osStatusError(-8))
        await assertAsyncThrows(error: BiometricsServiceError.biometryLocked) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` retrieves the key from keychain and updates integrity state.
    func test_getUserAuthKey_biometryFailed() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        let integrity = Data("Face/Off".utf8)
        biometricsService.biometricIntegrityState = integrity
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        keychainService.getResult = .failure(KeychainServiceError.osStatusError(kLAErrorBiometryDisconnected))
        await assertAsyncThrows(error: BiometricsServiceError.biometryFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` retrieves the key from keychain and updates integrity state.
    func test_getUserAuthKey_cancelled() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        let integrity = Data("Face/Off".utf8)
        biometricsService.biometricIntegrityState = integrity
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        // Send the user cancelled code.
        keychainService.getResult = .failure(KeychainServiceError.osStatusError(errSecUserCanceled))
        await assertAsyncThrows(error: BiometricsServiceError.biometryCancelled) {
            _ = try await subject.getUserAuthKey()
        }
    }

    /// `getUserAuthKey` retrieves the key from keychain and updates integrity state.
    func test_getUserAuthKey_unknownError() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        let integrity = Data("Face/Off".utf8)
        biometricsService.biometricIntegrityState = integrity
        stateService.biometricsEnabled = [
            active.profile.userId: true,
        ]
        keychainService.getResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
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

    /// `setBiometricUnlockKey` throws when there is a state service error.
    func test_setBiometricUnlockKey_nilValue_setBiometricIntegrityStateFailed() async throws {
        stateService.activeAccount = .fixture()
        stateService.setBiometricIntegrityStateError = TestError
            .mock("setBiometricIntegrityStateFailed")
        await assertAsyncThrows(
            error: TestError.mock("setBiometricIntegrityStateFailed")
        ) {
            try await subject.setBiometricUnlockKey(authKey: nil)
        }
    }

    /// `setBiometricUnlockKey` can remove a user key from the keychain and track the availbility in state.
    func test_setBiometricUnlockKey_nilValue_success() async throws {
        stateService.activeAccount = .fixture()
        try? await stateService.setBiometricAuthenticationEnabled(true)
        stateService.biometricIntegrityStates = [
            "1": "SomeState",
        ]
        keychainService.mockStorage = [
            "biometric_key_1": "storedKey",
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
        XCTAssertEqual("authKey", keychainService.mockStorage["biometric_key_1"])
        let result = try XCTUnwrap(stateService.biometricsEnabled["1"])
        XCTAssertTrue(result)
        XCTAssertEqual(keychainService.securityType, .biometryCurrentSet)
    }
}
