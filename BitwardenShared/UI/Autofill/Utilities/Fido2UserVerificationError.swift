// MARK: - Fido2UserVerificationError

/// Errors for Fido2 user verification flows.
enum Fido2UserVerificationError: Error {
    /// Master password reprompt was performed but failed to acknowledge.
    case masterPasswordRepromptFailed

    /// User verification has been performed, failed and the preference should be treated as required.
    case requiredEnforcementFailed
}
