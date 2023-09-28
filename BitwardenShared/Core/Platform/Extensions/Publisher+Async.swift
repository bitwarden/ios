import Combine

extension Publisher {
    /// Maps the output of a publisher to a different type, discarding any `nil` values.
    ///
    /// - Parameters:
    ///   - maxPublishers: The maximum number of concurrent publisher subscriptions.
    ///   - transform: The transform to apply to each output.
    /// - Returns: A publisher containing any non-`nil` mapped values.
    ///
    func asyncCompactMap<T>(
        maxPublishers: Subscribers.Demand = .max(1),
        _ transform: @escaping (Output) async -> T?
    ) -> Publishers.CompactMap<Publishers.FlatMap<Future<T?, Never>, Self>, T> {
        asyncMap(maxPublishers: maxPublishers, transform)
            .compactMap { $0 }
    }

    /// Maps the output of a publisher to a different type.
    ///
    /// - Parameters:
    ///   - maxPublishers: The maximum number of concurrent publisher subscriptions.
    ///   - transform: The transform to apply to each output.
    /// - Returns: A publisher containing the mapped values.
    ///
    func asyncMap<T>(
        maxPublishers: Subscribers.Demand = .max(1),
        _ transform: @escaping (Output) async -> T
    ) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap(maxPublishers: maxPublishers) { value in
            Future { promise in
                Task {
                    let output = await transform(value)
                    promise(.success(output))
                }
            }
        }
    }
}
