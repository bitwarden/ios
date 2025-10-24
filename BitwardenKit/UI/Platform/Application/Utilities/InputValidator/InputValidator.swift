/// A protocol for an object that handles validating input for a field.
///
protocol InputValidator {
    /// Validates that the specified input matches the requirements for the field.
    ///
    /// - Parameter input: The input to validate.
    ///
    func validate(input: String?) throws
}
