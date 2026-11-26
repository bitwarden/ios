import Combine

// MARK: - ActiveAccountIdPublisherProvider

/// Protocol for an object that publishes changes to the currently active account.
/// In practice, this is the `StateService` in each app.
public protocol ActiveAccountIdPublisherProvider: AnyObject { // sourcery: AutoMockable
    /// A publisher for the active account id.
    ///
    /// - Returns: The user ID for the active account, or `nil` if there isn't an active account.
    ///
    func activeAccountIdPublisher() async -> AnyPublisher<String?, Never>
}
