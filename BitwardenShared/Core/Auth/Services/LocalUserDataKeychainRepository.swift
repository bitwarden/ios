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

    /// Atomically clears all local user data key states for a user.
    /// Serialized against any in-flight mutations for `userId`, so a concurrent
    /// `mutateLocalUserDataKeyStates` cannot resurrect cleared state.
    ///
    /// - Parameter userId: The user ID associated with the local `UserKeyData` states.
    ///
    func clearLocalUserDataKeyStates(userId: String) async throws

    /// Atomically reads, transforms, and writes the local user data key states for a user.
    /// Concurrent calls for the same `userId` are serialized; calls for different user IDs are independent.
    ///
    /// - Parameters:
    ///   - userId: The user ID associated with the local `UserKeyData` states.
    ///   - transform: A closure that mutates the current key states in place.
    ///
    func mutateLocalUserDataKeyStates(
        userId: String,
        _ transform: @escaping @Sendable (inout [String: UserKeyData]) -> Void,
    ) async throws
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

    func clearLocalUserDataKeyStates(userId: String) async throws {
        try await localUserDataKeyStateMutationSerializer.enqueue(userId: userId) { [weak self] in
            guard let self else { return }
            try await setLocalUserDataKeyStates(nil, userId: userId)
        }
    }

    func mutateLocalUserDataKeyStates(
        userId: String,
        _ transform: @escaping @Sendable (inout [String: UserKeyData]) -> Void,
    ) async throws {
        try await localUserDataKeyStateMutationSerializer.enqueue(userId: userId) { [weak self] in
            guard let self else { return }
            var states = try await getLocalUserDataKeyStates(userId: userId) ?? [:]
            transform(&states)
            try await setLocalUserDataKeyStates(states.nilIfEmpty, userId: userId)
        }
    }

    private func setLocalUserDataKeyStates(_ states: [String: UserKeyData]?, userId: String) async throws {
        if let states {
            try await keychainServiceFacade.setValue(
                states,
                for: BitwardenKeychainItem.localUserDataKeyStates(userId: userId),
            )
        } else {
            try await keychainServiceFacade.deleteValue(
                for: BitwardenKeychainItem.localUserDataKeyStates(userId: userId),
            )
        }
    }
}
