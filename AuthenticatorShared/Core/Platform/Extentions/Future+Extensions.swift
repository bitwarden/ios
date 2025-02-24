import Combine

extension Future {
    /// Initialize a `Future` with an async throwing closure.
    ///
    /// - Parameter attemptToFulfill: A closure that the publisher invokes when it emits a value or
    ///     an error occurs.
    ///
    convenience init(_ attemptToFulfill: @Sendable @escaping () async throws -> Output) where Failure == Error {
        self.init { promise in
            Task {
                do {
                    let result = try await attemptToFulfill()
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}
