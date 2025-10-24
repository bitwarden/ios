// MARK: - InputValidationError

/// An error thrown by an `InputValidator` for invalid input in a field.
///
public struct InputValidationError: Error, Equatable {
    // MARK: Properties

    /// A localized error message describing the validation error.
    public let message: String

    // MARK: Initialization

    /// Initialize an input validation error.
    ///
    /// - Parameters:
    ///   - message: A localized error message describing the validation error.
    public init(message: String) {
        self.message = message
    }
}
