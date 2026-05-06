import Foundation

/// Serializes concurrent mutations to local user data key states per user ID using task chaining.
/// Each mutation awaits the previous one before reading from keychain, eliminating read/write race
/// conditions that would otherwise occur across actor suspension points.
public actor LocalUserDataKeyStateMutationSerializer {
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
