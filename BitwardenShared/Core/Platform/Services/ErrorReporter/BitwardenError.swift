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
        /// An error occurred during logout.
        case logoutError = 1000

        /// An error occurred persisting the generator options.
        case generatorOptionsError = 2000

        /// An error occurred with data from the API.
        case dataError = 3000

        /// A general-purpose error.
        case generalError = 4000
    }

    // MARK: Errors

    /// An error occurred relating to data from the API.
    ///
    /// - Parameter message: A message describing the error that occurred.
    ///
    static func dataError(_ message: String) -> NSError {
        NSError(
            domain: "Data Error",
            code: Code.dataError.rawValue,
            userInfo: [
                "ErrorMessage": message,
            ]
        )
    }

    /// A general-purpose error.
    ///
    /// - Parameters:
    ///   - type: The type of error. This is used to group the errors in the Crashlytics dashboard.
    ///   - message: A message describing the error that occurred.
    ///   - error: An optional underlying error that caused the error.
    ///
    static func generalError(type: String, message: String, error: Error? = nil) -> NSError {
        var userInfo: [String: Any] = ["ErrorMessage": message]
        if let error {
            userInfo[NSUnderlyingErrorKey] = error
        }
        return NSError(
            domain: "General Error: \(type)",
            code: Code.generalError.rawValue,
            userInfo: userInfo
        )
    }

    /// An error that occurred persisting the generator options.
    ///
    /// - Parameter error: The underlying error that caused the logout error.
    ///
    static func generatorOptionsError(error: Error) -> NSError {
        NSError(
            domain: "Generator Options Persisting Error",
            code: Code.generatorOptionsError.rawValue,
            userInfo: [
                NSUnderlyingErrorKey: error,
            ]
        )
    }

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
