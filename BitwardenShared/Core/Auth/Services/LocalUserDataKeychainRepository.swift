import BitwardenKit
import Foundation

/// A service that provides access to keychain values related to LocalUserData.
///
protocol LocalUserDataKeychainRepository { // sourcery: AutoMockable
    /// Gets the local user data key states for a user from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the local `UserKeyData` states.
    /// - Returns: A dictionary mapping key IDs to `UserKeyData`, or `nil` if not stored.
    ///
    func getLocalUserDataKeyStates(userId: String) async throws -> [String: UserKeyData]?

    /// Sets the local user data key states for a user in the keychain.
    /// Passing `nil` removes the stored states.
    ///
    /// - Parameters:
    ///   - states: The key states to store, or `nil` to remove.
    ///   - userId: The user ID associated with the local `UserKeyData` states.
    ///
    func setLocalUserDataKeyStates(_ states: [String: UserKeyData]?, userId: String) async throws
}

extension DefaultKeychainRepository: LocalUserDataKeychainRepository {
    func getLocalUserDataKeyStates(userId: String) async throws -> [String: UserKeyData]? {
        do {
            return try await keychainServiceFacade.getValue(
                for: BitwardenKeychainItem.localUserDataKeyStates(userId: userId),
            )
        } catch KeychainServiceError.osStatusError(errSecItemNotFound), KeychainServiceError.keyNotFound {
            return nil
        }
    }

    func setLocalUserDataKeyStates(_ states: [String: UserKeyData]?, userId: String) async throws {
        if let states {
            try await keychainServiceFacade.setValue(
                states,
                for: BitwardenKeychainItem.localUserDataKeyStates(userId: userId),
            )
        } else {
            try? await keychainServiceFacade.deleteValue(
                for: BitwardenKeychainItem.localUserDataKeyStates(userId: userId),
            )
        }
    }
}
