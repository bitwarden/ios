import Foundation

/// A service that provides state management functionality for `UserKeyData`.
///
protocol LocalUserDataStateService { // sourcery: AutoMockable
    /// Gets the local user data keys for the user ID
    ///
    /// - Parameters:
    ///   - userId: The user ID of the account.
    ///
    /// - Returns: A dictionary mapping SDK-assigned key identifiers to `UserKeyData`.
    ///
    func getLocalUserDataKeyStates(userId: String) async throws -> [String: UserKeyData]?

    /// Removes a single `UserKeyData` state for the user.
    ///
    /// - Parameters:
    ///   - id: The SDK-assigned key identifier.
    ///   - userId: The user ID of the account.
    ///
    func removeLocalUserDataKeyState(id: String, userId: String) async throws

    /// Removes all local user data key states for the user.
    ///
    /// - Parameter userId: The user ID of the account.
    ///
    func removeAllLocalUserDataKeyStates(userId: String) async throws

    /// Removes multiple `UserKeyData` states for the user.
    ///
    /// - Parameters:
    ///   - keys: The SDK-assigned key identifiers to remove.
    ///   - userId: The user ID of the account.
    ///
    func removeBulkLocalUserDataKeyStates(keys: [String], userId: String) async throws

    /// Sets a single `UserKeyData` state for the user.
    ///
    /// - Parameters:
    ///   - id: The SDK-assigned key identifier.
    ///   - value: The `UserKeyData` to store.
    ///   - userId: The user ID of the account.
    ///
    func setLocalUserDataKeyState(id: String, value: UserKeyData, userId: String) async throws

    /// Sets multiple `UserKeyData` states for the user.
    ///
    /// - Parameters:
    ///   - values: A dictionary mapping SDK-assigned key identifiers to `UserKeyData`.
    ///   - userId: The user ID of the account.
    ///
    func setBulkLocalUserDataKeyStates(_ values: [String: UserKeyData], userId: String) async throws
}

extension DefaultStateService: LocalUserDataStateService {
    func getLocalUserDataKeyStates(userId: String) async throws -> [String: UserKeyData]? {
        try await keychainRepository.getLocalUserDataKeyStates(userId: userId)
    }

    func removeLocalUserDataKeyState(id: String, userId: String) async throws {
        var states = try await keychainRepository.getLocalUserDataKeyStates(userId: userId) ?? [:]
        states.removeValue(forKey: id)
        try await keychainRepository.setLocalUserDataKeyStates(states.nilIfEmpty, userId: userId)
    }

    func removeAllLocalUserDataKeyStates(userId: String) async throws {
        try await keychainRepository.setLocalUserDataKeyStates(nil, userId: userId)
    }

    func removeBulkLocalUserDataKeyStates(keys: [String], userId: String) async throws {
        var states = try await keychainRepository.getLocalUserDataKeyStates(userId: userId) ?? [:]
        for key in keys {
            states.removeValue(forKey: key)
        }
        try await keychainRepository.setLocalUserDataKeyStates(states.nilIfEmpty, userId: userId)
    }

    func setLocalUserDataKeyState(id: String, value: UserKeyData, userId: String) async throws {
        var states = try await keychainRepository.getLocalUserDataKeyStates(userId: userId) ?? [:]
        states[id] = value
        try await keychainRepository.setLocalUserDataKeyStates(states, userId: userId)
    }

    func setBulkLocalUserDataKeyStates(_ values: [String: UserKeyData], userId: String) async throws {
        var states = try await keychainRepository.getLocalUserDataKeyStates(userId: userId) ?? [:]
        for (id, value) in values {
            states[id] = value
        }
        try await keychainRepository.setLocalUserDataKeyStates(states, userId: userId)
    }
}
