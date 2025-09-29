import BitwardenKit

/// Protocol to create `TOTPExpirationManager`.
protocol TOTPExpirationManagerFactory {
    /// Creates a `TOTPExpirationManager` passing the `onExpiration` closure.
    /// - Parameter onExpiration: Closure to execute on expiration.
    /// - Returns: A `TOTPExpirationManager` configured with the given closure.
    func create(onExpiration: (([VaultListItem]) -> Void)?) -> TOTPExpirationManager
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

    func create(onExpiration: (([VaultListItem]) -> Void)?) -> TOTPExpirationManager {
        DefaultTOTPExpirationManager(timeProvider: timeProvider, onExpiration: onExpiration)
    }
}
