import Foundation

/// The state for the TOTP autofill form test screen.
///
struct TOTPAutofillFormState: Equatable {
    // MARK: Properties

    /// The TOTP code field value.
    var totpCode: String = ""
}
