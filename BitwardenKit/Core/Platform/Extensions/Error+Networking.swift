import Foundation

public extension Error {
    /// Attempts to determine if the error should not be logged, like a networking related error.
    /// This can be useful for deciding if the error should be logged to an external error reporting service where
    /// networking or server errors may add noise instead of being actionable errors that need to
    /// be fixed in the app.
    var isNonLoggableError: Bool {
        if self is NonLoggableError || self is URLError {
            return true
        }

        if let keychainError = self as? KeychainServiceError,
           case let .osStatusError(status) = keychainError {
            return status == errSecMissingEntitlement
        }

        return false
    }
}
