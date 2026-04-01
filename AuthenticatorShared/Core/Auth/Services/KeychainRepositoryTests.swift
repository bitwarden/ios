import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import AuthenticatorShared

// MARK: - KeychainRepositoryTests

class KeychainRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var keychainServiceFacade: MockKeychainServiceFacade!
    var subject: DefaultKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        keychainServiceFacade = MockKeychainServiceFacade()
        subject = DefaultKeychainRepository(keychainServiceFacade: keychainServiceFacade)
    }

    override func tearDown() {
        super.tearDown()

        keychainServiceFacade = nil
        subject = nil
    }

    // MARK: Tests - secretKey

    /// `getSecretKey(userId:)` returns the secret key from the façade.
    ///
    func test_getSecretKey_success() async throws {
        keychainServiceFacade.getValueReturnValue = "secret-value"

        let result = try await subject.getSecretKey(userId: "user-1")

        XCTAssertEqual(result, "secret-value")
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            AuthenticatorKeychainItem.secretKey(userId: "user-1").unformattedKey,
        )
    }

    /// `getSecretKey(userId:)` rethrows errors from the façade.
    ///
    func test_getSecretKey_rethrows() async {
        let item = AuthenticatorKeychainItem.secretKey(userId: "user-1")
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(item)

        await assertAsyncThrows(error: KeychainServiceError.keyNotFound(item)) {
            _ = try await subject.getSecretKey(userId: "user-1")
        }
    }

    /// `setSecretKey(_:userId:)` stores the secret key via the façade.
    ///
    func test_setSecretKey_success() async throws {
        try await subject.setSecretKey("new-secret", userId: "user-1")

        XCTAssertEqual(keychainServiceFacade.setValueReceivedArguments?.value, "new-secret")
        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey,
            AuthenticatorKeychainItem.secretKey(userId: "user-1").unformattedKey,
        )
    }

    /// `setSecretKey(_:userId:)` rethrows errors from the façade.
    ///
    func test_setSecretKey_rethrows() async {
        keychainServiceFacade.setValueThrowableError = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(errSecInteractionNotAllowed)) {
            try await subject.setSecretKey("new-secret", userId: "user-1")
        }
    }

    // MARK: Tests - BiometricsKeychainRepository

    /// `deleteUserBiometricAuthKey(userId:)` deletes the user biometrics auth key via the façade.
    ///
    func test_deleteUserBiometricAuthKey_success() async throws {
        try await subject.deleteUserBiometricAuthKey(userId: "user-1")

        XCTAssertEqual(
            keychainServiceFacade.deleteValueReceivedItem?.unformattedKey,
            AuthenticatorKeychainItem.biometrics(userId: "user-1").unformattedKey,
        )
    }

    /// `deleteUserBiometricAuthKey(userId:)` rethrows errors from the façade.
    ///
    func test_deleteUserBiometricAuthKey_rethrows() async {
        let error = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)
        keychainServiceFacade.deleteValueThrowableError = error

        await assertAsyncThrows(error: error) {
            try await subject.deleteUserBiometricAuthKey(userId: "user-1")
        }
    }

    /// `getUserBiometricAuthKey(userId:)` returns the user biometrics auth key from the façade.
    ///
    func test_getUserBiometricAuthKey_success() async throws {
        keychainServiceFacade.getValueReturnValue = "biometric-key"

        let result = try await subject.getUserBiometricAuthKey(userId: "user-1")

        XCTAssertEqual(result, "biometric-key")
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            AuthenticatorKeychainItem.biometrics(userId: "user-1").unformattedKey,
        )
    }

    /// `getUserBiometricAuthKey(userId:)` rethrows errors from the façade.
    ///
    func test_getUserBiometricAuthKey_rethrows() async {
        let error = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)
        keychainServiceFacade.getValueThrowableError = error

        await assertAsyncThrows(error: error) {
            _ = try await subject.getUserBiometricAuthKey(userId: "user-1")
        }
    }

    /// `setUserBiometricAuthKey(userId:value:)` stores the user biometrics auth key via the façade.
    ///
    func test_setUserBiometricAuthKey_success() async throws {
        try await subject.setUserBiometricAuthKey(userId: "user-1", value: "biometric-key")

        XCTAssertEqual(keychainServiceFacade.setValueReceivedArguments?.value, "biometric-key")
        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey,
            AuthenticatorKeychainItem.biometrics(userId: "user-1").unformattedKey,
        )
    }

    /// `setUserBiometricAuthKey(userId:value:)` rethrows errors from the façade.
    ///
    func test_setUserBiometricAuthKey_rethrows() async {
        let error = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)
        keychainServiceFacade.setValueThrowableError = error

        await assertAsyncThrows(error: error) {
            try await subject.setUserBiometricAuthKey(userId: "user-1", value: "biometric-key")
        }
    }
}
