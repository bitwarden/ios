import Foundation

/// A type used to construct errors that are reported to the error reporter.
///
/// Each type of error should have a unique `code`. Non-fatal errors in Crashlytics are grouped by
/// the `domain` and `code`.
///
enum BitwardenError {
    // MARK: Types

    /// An error code for the error.
    ///
    enum Code: Int {
        case logoutError = 1000
    }

    // MARK: Errors

    /// An error that occurred during logout.
    ///
    /// - Parameter error: The underlying error that caused the logout error.
    ///
    static func logoutError(error: Error) -> NSError {
        NSError(
            domain: "Logout Error",
            code: Code.logoutError.rawValue,
            userInfo: [
                NSUnderlyingErrorKey: error,
            ]
        )
    }
}
