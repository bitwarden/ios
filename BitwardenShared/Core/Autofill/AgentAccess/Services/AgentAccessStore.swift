import BitwardenKit
import Foundation

// MARK: - AgentAccessStore

/// A protocol for a store that persists the Agent Access data of each user in the keychain.
///
protocol AgentAccessStore: AnyObject { // sourcery: AutoMockable
    /// Appends an entry to the audit log of a user, newest first, dropping the oldest entries
    /// beyond `AgentAccessConstants.maxAuditEntries`.
    ///
    /// - Parameters:
    ///   - entry: The entry to append.
    ///   - userId: The ID of the user.
    ///
    func appendAudit(_ entry: AgentAccessAuditEntry, userId: String) async throws

    /// Deletes everything stored for a user.
    ///
    /// - Parameter userId: The ID of the user.
    ///
    func delete(userId: String) async throws

    /// Atomically reads, transforms and writes the data of a user. Concurrent calls for the same
    /// user are serialized.
    ///
    /// - Parameters:
    ///   - userId: The ID of the user.
    ///   - transform: A closure that mutates the current data in place.
    ///
    func update(
        userId: String,
        _ transform: @escaping @Sendable (inout AgentAccessUserData) -> Void,
    ) async throws

    /// Gets the data of a user, or empty data if nothing is stored yet.
    ///
    /// - Parameter userId: The ID of the user.
    /// - Returns: The data of the user.
    ///
    func userData(userId: String) async throws -> AgentAccessUserData
}

// MARK: - DefaultAgentAccessStore

/// The default implementation of `AgentAccessStore`.
///
final class DefaultAgentAccessStore: AgentAccessStore {
    // MARK: Properties

    /// The repository used to read and write the keychain item of a user.
    private let keychainRepository: AgentAccessKeychainRepository

    /// Serializes the read-modify-write cycles of each user.
    private let serializer = SerialWorker()

    // MARK: Initialization

    /// Initialize a `DefaultAgentAccessStore`.
    ///
    /// - Parameter keychainRepository: The repository used to read and write the keychain item of a user.
    ///
    init(keychainRepository: AgentAccessKeychainRepository) {
        self.keychainRepository = keychainRepository
    }

    // MARK: AgentAccessStore

    func appendAudit(_ entry: AgentAccessAuditEntry, userId: String) async throws {
        try await update(userId: userId) { data in
            data.audit.insert(entry, at: 0)
            if data.audit.count > AgentAccessConstants.maxAuditEntries {
                data.audit.removeLast(data.audit.count - AgentAccessConstants.maxAuditEntries)
            }
        }
    }

    func delete(userId: String) async throws {
        try await serializer.enqueue(userId: userId) { [keychainRepository] in
            try await keychainRepository.deleteAgentAccessState(userId: userId)
        }
    }

    func update(
        userId: String,
        _ transform: @escaping @Sendable (inout AgentAccessUserData) -> Void,
    ) async throws {
        try await serializer.enqueue(userId: userId) { [keychainRepository] in
            var data = try await keychainRepository.getAgentAccessState(userId: userId) ?? AgentAccessUserData()
            transform(&data)
            try await keychainRepository.setAgentAccessState(data, userId: userId)
        }
    }

    func userData(userId: String) async throws -> AgentAccessUserData {
        try await keychainRepository.getAgentAccessState(userId: userId) ?? AgentAccessUserData()
    }
}
