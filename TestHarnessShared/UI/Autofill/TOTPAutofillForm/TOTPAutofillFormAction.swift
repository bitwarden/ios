import Foundation

/// Actions that can be processed by a `TOTPAutofillFormProcessor`.
///
enum TOTPAutofillFormAction: Equatable {
    /// The TOTP code field was updated.
    case totpCodeChanged(String)
}
