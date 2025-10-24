import BitwardenResources

// MARK: - EmptyInputValidator

/// Validates that the input for a field is not empty.
///
public struct EmptyInputValidator: InputValidator {
    // MARK: Properties

    /// The name of the field that is being validated.
    public let fieldName: String

    // MARK: Initializer

    /// Initializes an `EmptyInputValidator`.
    ///
    /// - Parameters:
    ///   - fieldName: The name of the field that is being validated.
    public init(fieldName: String) {
        self.fieldName = fieldName
    }

    // MARK: InputValidator

    public func validate(input: String?) throws {
        guard input?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw InputValidationError(message: Localizations.validationFieldRequired(fieldName))
        }
    }
}
