import BitwardenResources

/// Validates that the input for a field is not empty.
///
struct EmptyInputValidator: InputValidator {
    // MARK: Properties

    /// The name of the field that is being validated.
    let fieldName: String

    // MARK: InputValidator

    func validate(input: String?) throws {
        guard input?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw InputValidationError(message: Localizations.validationFieldRequired(fieldName))
        }
    }
}
