import Foundation

public extension Error {
    /// Attempts to determine if the error should not be logged, like a networking related error.
    /// This can be useful for deciding if the error should be logged to an external error reporting service where
    /// networking or server errors may add noise instead of being actionable errors that need to
    /// be fixed in the app.
    var isNonLoggableError: Bool {
        switch self {
        case is NonLoggableError, // Any error marked as `NetworkingError`
             is URLError: // URLSession errors.
            true
        default:
            false
        }
    }
}
