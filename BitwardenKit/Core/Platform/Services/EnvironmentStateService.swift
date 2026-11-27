// MARK: - EnvironmentStateService

/// A protocol for a service that provides state management functionality required by the environment service.
///
public protocol EnvironmentStateService: AnyObject { // sourcery: AutoMockable
    /// Gets the environment URLs for a user ID.
    ///
    /// - Parameters:
    ///   - userId: The user ID associated with the environment URLs. Defaults to the active account if `nil`.
    /// - Returns: The user's environment URLs.
    ///
    func getEnvironmentURLs(userId: String?) async throws -> EnvironmentURLData?

    /// Gets the environment URLs used by the app prior to the user authenticating.
    ///
    /// - Returns: The environment URLs used prior to user authentication.
    ///
    func getPreAuthEnvironmentURLs() async -> EnvironmentURLData?

    /// Sets the environment URLs used prior to user authentication.
    ///
    /// - Parameters:
    ///   - urls: The environment URLs used prior to user authentication.
    ///
    func setPreAuthEnvironmentURLs(_ urls: EnvironmentURLData) async
}

public extension EnvironmentStateService {
    /// Gets the environment URLs for the active account.
    ///
    /// - Returns: The environment URLs for the active account.
    ///
    func getEnvironmentURLs() async throws -> EnvironmentURLData? {
        try await getEnvironmentURLs(userId: nil)
    }
}
