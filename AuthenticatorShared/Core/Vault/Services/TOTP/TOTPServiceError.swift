/// Enum representing errors in the TOTP Service.
///
enum TOTPServiceError: Error, Equatable {
    /// `invalidKeyFormat` is thrown when the TOTP key is not in a recognized or valid format.
    case invalidKeyFormat

    /// `unableToGenerateCode` is thrown when the TOTP code cannot be generated.
    case unableToGenerateCode(_ errorDescription: String?)
}
