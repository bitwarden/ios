import Foundation

// MARK: - AgentAccessBlocking

/// Runs async work from the synchronous SDK callbacks. The SDK calls its callbacks on threads it
/// owns, so blocking here never starves the Swift concurrency pool.
///
enum AgentAccessBlocking {
    // MARK: Types

    /// Carries the result of the async work back to the blocked thread.
    private final class ResultBox<T>: @unchecked Sendable {
        var result: Result<T, Error>?
    }

    // MARK: Methods

    /// Runs the operation and blocks the calling thread until it finishes.
    ///
    /// - Parameter operation: The work to run.
    /// - Returns: The result of the work.
    ///
    static func run<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) throws -> T {
        let box = ResultBox<T>()
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached {
            do {
                box.result = try await .success(operation())
            } catch {
                box.result = .failure(error)
            }
            semaphore.signal()
        }
        semaphore.wait()
        guard let result = box.result else { throw AgentAccessError.requestNotFound }
        return try result.get()
    }
}
