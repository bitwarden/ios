import Foundation

@testable import BitwardenShared

/// An `AgentAccessKeychainRepository` that keeps the state of each user in memory.
///
final class InMemoryAgentAccessKeychainRepository: AgentAccessKeychainRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var states: [String: AgentAccessUserData] = [:]
    var getError: Error?

    func deleteAgentAccessState(userId: String) async throws {
        lock.lock()
        defer { lock.unlock() }
        states[userId] = nil
    }

    func getAgentAccessState(userId: String) async throws -> AgentAccessUserData? {
        if let getError { throw getError }
        lock.lock()
        defer { lock.unlock() }
        return states[userId]
    }

    func setAgentAccessState(_ state: AgentAccessUserData, userId: String) async throws {
        lock.lock()
        defer { lock.unlock() }
        states[userId] = state
    }
}
