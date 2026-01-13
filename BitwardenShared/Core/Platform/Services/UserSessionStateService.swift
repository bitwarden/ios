import BitwardenKit
import Foundation

// MARK: - UserSessionStateService

/// A service that provides state management functionality around user session values.
///
protocol UserSessionStateService {
    /// Gets the user's last active time within the app.
    /// This value is set when the app is backgrounded.
    ///
    /// - Parameter userId: The user ID associated with the last active time within the app.
    /// - Returns: The date of the last active time.
    ///
    func getLastActiveTime(userId: String?) async throws -> Date?

    /// Sets the last active time within the app.
    ///
    /// - Parameters:
    ///   - date: The current time.
    ///   - userId: The user ID associated with the last active time within the app.
    ///
    func setLastActiveTime(_ date: Date?, userId: String?) async throws

    /// Gets the session timeout value.
    ///
    /// - Parameter userId: The user ID for the account.
    /// - Returns: The session timeout value.
    ///
    func getVaultTimeout(userId: String?) async throws -> SessionTimeoutValue

    /// Sets the session timeout value.
    ///
    /// - Parameters:
    ///   - value: The value that dictates how many seconds in the future a timeout should occur.
    ///   - userId: The user ID associated with the timeout value.
    ///
    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws
}
