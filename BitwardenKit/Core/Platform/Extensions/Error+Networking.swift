import Foundation

public extension Error {
    /// Attempts to determine if the error is a networking related error. This can be useful for
    /// deciding if the error should be logged to an external error reporting service where
    /// networking or server errors may add noise instead of being actionable errors that need to
    /// be fixed in the app.
    var isNetworkingError: Bool {
        switch self {
        case is ResponseValidationError, // Bitwarden Server specific errors.
             is ServerError, // Any other non-2XX HTTP errors.
             is URLError: // URLSession errors.
            true
        default:
            false
        }
    }
}
