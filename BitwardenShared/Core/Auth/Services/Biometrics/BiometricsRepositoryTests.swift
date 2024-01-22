import XCTest

@testable import BitwardenShared

// MARK: - BiometricsRepositoryTests

final class BiometricsRepositoryTests: BitwardenTestCase {
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

    func test_configureBiometricIntegrity_noData() async throws {
        biometricsService.biometricIntegrityState = nil
        stateService.activeAccount = .fixture()
        stateService.setBiometricIntegrityStateError = nil
        try await subject.configureBiometricIntegrity()
        XCTAssertTrue(stateService.biometricIntegrityStates.isEmpty)
    }

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

    func test_getBiometricUnlockKey_noActiveAccount() async throws {
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getUserAuthKey()
        }
    }

    func test_getBiometricUnlockKey_keychainServiceError() async throws {
        stateService.activeAccount = .fixture()
        keychainService.getResult = .failure(
            KeychainServiceError.keyNotFound(.biometrics(userId: "1"))
        )
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    func test_getBiometricUnlockKey_emptyString() async throws {
        let expectedKey = ""
        stateService.activeAccount = .fixture()
        keychainService.getResult = .success(expectedKey)
        await assertAsyncThrows(error: BiometricsServiceError.getAuthKeyFailed) {
            _ = try await subject.getUserAuthKey()
        }
    }

    func test_getBiometricUnlockKey_success() async throws {
        let expectedKey = "expectedKey"
        stateService.activeAccount = .fixture()
        keychainService.getResult = .success(expectedKey)
        let key = try await subject.getUserAuthKey()
        XCTAssertEqual(key, expectedKey)
    }

    func test_setBiometricUnlockKey_nilValue_noActiveAccount() async throws {
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.setBiometricUnlockKey(authKey: nil)
        }
    }

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

    func test_setBiometricUnlockKey_nilValue_successWithKeychainError() async throws {
        stateService.activeAccount = .fixture()
        stateService.setBiometricAuthenticationEnabledResult = .success(())
        keychainService.deleteResult = .failure(KeychainServiceError.osStatusError(13))
        await assertAsyncDoesNotThrow {
            try await subject.setBiometricUnlockKey(authKey: nil)
        }
    }

    func test_setBiometricUnlockKey_withValue_noActiveAccount() async throws {
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.setBiometricUnlockKey(authKey: "authKey")
        }
    }

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
