/// Enum representing errors in the TOTP Service.
///
enum TOTPServiceError: Error, Equatable {
    /// `unableToGenerateCode` is thrown when the TOTP code cannot be generated.
    case unableToGenerateCode(_ errorDescription: String?)
}
