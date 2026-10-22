import BitwardenKit
import Foundation

// MARK: - AgentAccessKeychainRepository

/// A service that provides access to the keychain item holding a user's Agent Access state.
///
protocol AgentAccessKeychainRepository { // sourcery: AutoMockable
    /// Deletes the Agent Access state of a user from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the state.
    ///
    func deleteAgentAccessState(userId: String) async throws

    /// Gets the Agent Access state of a user from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the state.
    /// - Returns: The state, or `nil` if none is stored.
    ///
    func getAgentAccessState(userId: String) async throws -> AgentAccessUserData?

    /// Stores the Agent Access state of a user in the keychain.
    ///
    /// - Parameters:
    ///   - state: The state to store.
    ///   - userId: The user ID associated with the state.
    ///
    func setAgentAccessState(_ state: AgentAccessUserData, userId: String) async throws
}

// MARK: Agent Access State

extension DefaultKeychainRepository: AgentAccessKeychainRepository {
    func deleteAgentAccessState(userId: String) async throws {
        try await keychainServiceFacade.deleteValue(for: BitwardenKeychainItem.agentAccessState(userId: userId))
    }

    func getAgentAccessState(userId: String) async throws -> AgentAccessUserData? {
        do {
            return try await keychainServiceFacade.getValue(
                for: BitwardenKeychainItem.agentAccessState(userId: userId),
            )
        } catch KeychainServiceError.osStatusError(errSecItemNotFound), KeychainServiceError.keyNotFound {
            return nil
        }
    }

    func setAgentAccessState(_ state: AgentAccessUserData, userId: String) async throws {
        try await keychainServiceFacade.setValue(
            state,
            for: BitwardenKeychainItem.agentAccessState(userId: userId),
        )
    }
}
