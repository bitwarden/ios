import BitwardenKit
import Foundation

// MARK: - LocalUserDataKeyStateMutationSerializer

/// Serializes concurrent mutations to local user data key states per user ID using task chaining.
/// Each mutation awaits the previous one before reading from keychain, eliminating read/write race
/// conditions that would otherwise occur across actor suspension points.
actor LocalUserDataKeyStateMutationSerializer {
    // MARK: Properties

    private var pendingMutationsByUserId: [String: Task<Void, Error>] = [:]

    // MARK: Methods

    /// Serializes `operation` after any in-progress mutation for `userId`.
    func serialize(userId: String, operation: @escaping @Sendable () async throws -> Void) async throws {
        let previous = pendingMutationsByUserId[userId]
        let task = Task<Void, Error> {
            // ensure previous mutation is finished
            _ = try? await previous?.value
            try await operation()
        }
        pendingMutationsByUserId[userId] = task
        try await task.value
    }
}

// MARK: - LocalUserDataKeychainRepository

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

    func setLocalUserDataKeyStates(_ states: [String: UserKeyData]?, userId: String) async throws {
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

    func clearLocalUserDataKeyStates(userId: String) async throws {
        try await localUserDataKeyStateMutationSerializer.serialize(userId: userId) { [weak self] in
            guard let self else { return }
            try await setLocalUserDataKeyStates(nil, userId: userId)
        }
    }

    func mutateLocalUserDataKeyStates(userId: String,
                                      _ transform: @escaping @Sendable (inout [String: UserKeyData]) -> Void
                                     ) async throws {
        try await localUserDataKeyStateMutationSerializer.serialize(userId: userId) { [weak self] in
            guard let self else { return }
            var states = try await getLocalUserDataKeyStates(userId: userId) ?? [:]
            transform(&states)
            try await setLocalUserDataKeyStates(states.nilIfEmpty, userId: userId)
        }
    }
}
