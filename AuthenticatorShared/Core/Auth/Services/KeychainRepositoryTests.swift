import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

@testable import AuthenticatorShared

// MARK: - KeychainRepositoryTests

struct KeychainRepositoryTests {
    // MARK: Properties

    var keychainServiceFacade: MockKeychainServiceFacade!
    var subject: DefaultKeychainRepository!

    // MARK: Setup & Teardown

    init() {
        keychainServiceFacade = MockKeychainServiceFacade()
        subject = DefaultKeychainRepository(keychainServiceFacade: keychainServiceFacade)
    }

    // MARK: Tests - secretKey

    /// `getSecretKey(userId:)` returns the secret key from the façade.
    @Test
    func getSecretKey_success() async throws {
        keychainServiceFacade.getValueReturnValue = "secret-value"

        let result = try await subject.getSecretKey(userId: "user-1")

        #expect(result == "secret-value")

        let actualReceivedItem = keychainServiceFacade.getValueReceivedItem as? AuthenticatorKeychainItem
        let expectedReceivedItem = AuthenticatorKeychainItem.secretKey(userId: "user-1")
        #expect(actualReceivedItem == expectedReceivedItem)
    }

    /// `getSecretKey(userId:)` rethrows errors from the façade.
    @Test
    func getSecretKey_rethrows() async {
        let item = AuthenticatorKeychainItem.secretKey(userId: "user-1")
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(item)

        await #expect(throws: KeychainServiceError.keyNotFound(item)) {
            _ = try await subject.getSecretKey(userId: "user-1")
        }
    }

    /// `setSecretKey(_:userId:)` stores the secret key via the façade.
    @Test
    func setSecretKey_success() async throws {
        try await subject.setSecretKey("new-secret", userId: "user-1")

        #expect(keychainServiceFacade.setValueReceivedArguments?.value == "new-secret")

        let actualReceivedItem = keychainServiceFacade.setValueReceivedArguments?.item as? AuthenticatorKeychainItem
        let expectedReceivedItem = AuthenticatorKeychainItem.secretKey(userId: "user-1")
        #expect(actualReceivedItem == expectedReceivedItem)
    }

    /// `setSecretKey(_:userId:)` rethrows errors from the façade.
    @Test
    func setSecretKey_rethrows() async {
        let expectedError = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)
        keychainServiceFacade.setValueThrowableError = expectedError

        await #expect(throws: expectedError) {
            try await subject.setSecretKey("new-secret", userId: "user-1")
        }
    }

    // MARK: Tests - BiometricsKeychainRepository

    /// `deleteUserBiometricAuthKey(userId:)` deletes the user biometrics auth key via the façade.
    @Test
    func deleteUserBiometricAuthKey_success() async throws {
        try await subject.deleteUserBiometricAuthKey(userId: "user-1")

        let actualReceivedItem = keychainServiceFacade.deleteValueReceivedItem as? AuthenticatorKeychainItem
        let expectedReceivedItem = AuthenticatorKeychainItem.biometrics(userId: "user-1")
        #expect(actualReceivedItem == expectedReceivedItem)
    }

    /// `deleteUserBiometricAuthKey(userId:)` rethrows errors from the façade.
    @Test
    func deleteUserBiometricAuthKey_rethrows() async {
        let expectedError = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)
        keychainServiceFacade.deleteValueThrowableError = expectedError

        await #expect(throws: expectedError) {
            try await subject.deleteUserBiometricAuthKey(userId: "user-1")
        }
    }

    /// `getUserBiometricAuthKey(userId:)` returns the user biometrics auth key from the façade.
    @Test
    func getUserBiometricAuthKey_success() async throws {
        keychainServiceFacade.getValueReturnValue = "biometric-key"

        let result = try await subject.getUserBiometricAuthKey(userId: "user-1")

        #expect(result == "biometric-key")

        let actualReceivedItem = keychainServiceFacade.getValueReceivedItem as? AuthenticatorKeychainItem
        let expectedReceivedItem = AuthenticatorKeychainItem.biometrics(userId: "user-1")
        #expect(actualReceivedItem == expectedReceivedItem)
    }

    /// `getUserBiometricAuthKey(userId:)` rethrows errors from the façade.
    @Test
    func getUserBiometricAuthKey_rethrows() async {
        let expectedError = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)
        keychainServiceFacade.getValueThrowableError = expectedError

        await #expect(throws: expectedError) {
            _ = try await subject.getUserBiometricAuthKey(userId: "user-1")
        }
    }

    /// `setUserBiometricAuthKey(userId:value:)` stores the user biometrics auth key via the façade.
    @Test
    func setUserBiometricAuthKey_success() async throws {
        try await subject.setUserBiometricAuthKey(userId: "user-1", value: "biometric-key")

        #expect(keychainServiceFacade.setValueReceivedArguments?.value == "biometric-key")

        let actualReceivedItem = keychainServiceFacade.setValueReceivedArguments?.item as? AuthenticatorKeychainItem
        let expectedReceivedItem = AuthenticatorKeychainItem.biometrics(userId: "user-1")
        #expect(actualReceivedItem == expectedReceivedItem)
    }

    /// `setUserBiometricAuthKey(userId:value:)` rethrows errors from the façade.
    @Test
    func setUserBiometricAuthKey_rethrows() async {
        let expectedError = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)
        keychainServiceFacade.setValueThrowableError = expectedError

        await #expect(throws: expectedError) {
            try await subject.setUserBiometricAuthKey(userId: "user-1", value: "biometric-key")
        }
    }
}
