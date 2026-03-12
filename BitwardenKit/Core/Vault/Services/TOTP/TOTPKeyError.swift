/// Errors related to an invalid or missing TOTP key, representing user-correctable
/// data issues. Conforms to `NonLoggableError` so these are not sent to Crashlytics.
///
public enum TOTPKeyError: NonLoggableError, Equatable {
    /// Thrown when the TOTP key is not in a recognized or valid format.
    case invalidKeyFormat

    /// Thrown when the TOTP key's OTP auth URI is not valid.
    case invalidOtpauth

    /// Thrown when the TOTP key has no associated secret.
    case missingSecret
}
