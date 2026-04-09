import BitwardenResources
import Foundation

// MARK: - ActiveAccountStateProvider

/// Protocol wrapping information about the currently active account.
/// In practice, this is the `StateService` in each app.
public protocol ActiveAccountStateProvider: AnyObject { // sourcery: AutoMockable
    /// Gets the active account id.
    ///
    /// - Returns: The active user account id.
    ///
    func getActiveAccountId() async throws -> String
}

public extension ActiveAccountStateProvider {
    /// Returns the provided user ID if it exists, otherwise fetches the active account's ID.
    ///
    /// - Parameter maybeId: The optional user ID to check.
    /// - Returns: The user ID if provided, otherwise the active account's ID.
    /// - Throws: An error if fetching the active account ID fails.
    ///
    func userIdOrActive(_ maybeId: String?) async throws -> String {
        if let maybeId { return maybeId }
        return try await getActiveAccountId()
    }
}
