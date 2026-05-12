import Foundation

/// Serializes concurrent operations per user ID using task chaining.
/// Each operation awaits the previous one before running, eliminating race
/// conditions that would otherwise occur across actor suspension points such as `await`.
actor SerialWorker {
    /// Dictionary of pending operations to be run, indexed by `userId`.
    private var pendingOperations: [String: Task<Void, Error>] = [:]

    /// Serializes `operation` after any in-progress mutation for `userId`.
    func enqueue(userId: String, operation: @escaping @Sendable () async throws -> Void) async throws {
        let previous = pendingOperations[userId]
        let task = Task<Void, Error> {
            // ensure previous operation is finished
            _ = try? await previous?.value
            try await operation()
        }
        pendingOperations[userId] = task
        try await task.value
    }
}
