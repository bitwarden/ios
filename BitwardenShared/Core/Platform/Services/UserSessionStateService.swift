import BitwardenKit
import Foundation

// MARK: - UserSessionStateService

/// A service that provides state management functionality around user session values.
///
protocol UserSessionStateService { // sourcery: AutoMockable
    // MARK: Last Active Time

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

    // MARK: Unsuccessful Unlock Attempts

    /// Gets the number of unsuccessful attempts to unlock the vault for a user ID.
    ///
    /// - Parameter userId: The optional user ID associated with the unsuccessful unlock attempts,
    /// if `nil` defaults to currently active user.
    /// - Returns: The number of unsuccessful attempts to unlock the vault.
    ///
    func getUnsuccessfulUnlockAttempts(userId: String?) async throws -> Int

    /// Sets the number of unsuccessful attempts to unlock the vault for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the unsuccessful unlock attempts.
    /// if `nil` defaults to currently active user.
    ///
    func setUnsuccessfulUnlockAttempts(_ attempts: Int, userId: String?) async throws

    // MARK: Vault Timeout

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
    func setVaultTimeout(_ value: SessionTimeoutValue, userId: String?) async throws
}

/// Convenience functions for the current user.
extension UserSessionStateService {
    // MARK: Last Active Time

    /// Gets the user's last active time within the app.
    /// This value is set when the app is backgrounded.
    ///
    /// - Returns: The date of the last active time.
    ///
    func getLastActiveTime() async throws -> Date? {
        try await getLastActiveTime(userId: nil)
    }

    /// Sets the last active time within the app.
    ///
    /// - Parameter date: The current time.
    ///
    func setLastActiveTime(_ date: Date?) async throws {
        try await setLastActiveTime(date, userId: nil)
    }

    // MARK: Unsuccessful Unlock Attempts

    /// Sets the number of unsuccessful attempts to unlock the vault for the active account.
    ///
    /// - Returns: The number of unsuccessful unlock attempts for the active account.
    ///
    func getUnsuccessfulUnlockAttempts() async -> Int {
        if let attempts = try? await getUnsuccessfulUnlockAttempts(userId: nil) {
            return attempts
        }
        return 0
    }

    /// Sets the number of unsuccessful attempts to unlock the vault for the active account.
    ///
    /// - Parameter attempts: The number of unsuccessful unlock attempts.
    ///
    func setUnsuccessfulUnlockAttempts(_ attempts: Int) async {
        try? await setUnsuccessfulUnlockAttempts(attempts, userId: nil)
    }

    // MARK: Vault Timeout

    /// Gets the session timeout value.
    ///
    /// - Returns: The session timeout value.
    ///
    func getVaultTimeout() async throws -> SessionTimeoutValue {
        try await getVaultTimeout(userId: nil)
    }

    /// Sets the session timeout value.
    ///
    /// - Parameter value: The value that dictates how many seconds in the future a timeout should occur.
    ///
    func setVaultTimeout(_ value: SessionTimeoutValue) async throws {
        try await setVaultTimeout(value, userId: nil)
    }
}
