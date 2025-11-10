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
