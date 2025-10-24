/// An error thrown by an `InputValidator` for invalid input in a field.
///
struct InputValidationError: Error, Equatable {
    // MARK: Properties

    /// A localized error message describing the validation error.
    let message: String
}
