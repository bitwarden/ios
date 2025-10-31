import BitwardenKit
import Combine

/// Protocol to create `TOTPExpirationManager`.
protocol TOTPExpirationManagerFactory {
    /// Creates a `TOTPExpirationManager` passing the `onExpiration` closure.
    /// - Parameters
    ///     - itemPublisher: A publisher that emits the current list of vault sections whenever they change.
    ///     - onExpiration: Closure to execute on expiration.
    /// - Returns: A `TOTPExpirationManager` configured with the given closure.
    func create(itemPublisher: AnyPublisher<[ItemListSection]?, Never>,
                onExpiration: (([ItemListItem]) -> Void)?) -> TOTPExpirationManager
}

/// The default implementation of `TOTPExpirationManagerFactory`.
class DefaultTOTPExpirationManagerFactory: TOTPExpirationManagerFactory {
    /// The service used to get the present time.
    var timeProvider: TimeProvider

    /// Initializes a `DefaultTOTPExpirationManagerFactory`.
    /// - Parameter timeProvider: The service used to get the present time.
    init(timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
    }

    func create(itemPublisher: AnyPublisher<[ItemListSection]?, Never>,
                onExpiration: (([ItemListItem]) -> Void)?) -> TOTPExpirationManager {
        DefaultTOTPExpirationManager(itemPublisher: itemPublisher,
                                     onExpiration: onExpiration,
                                     timeProvider: timeProvider)
    }
}
