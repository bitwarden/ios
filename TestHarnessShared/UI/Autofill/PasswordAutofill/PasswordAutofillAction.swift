import Foundation

/// Actions that can be processed by a `PasswordAutofillProcessor`.
///
enum PasswordAutofillAction: Equatable {
    /// The password field was updated.
    case passwordChanged(String)

    /// The username field was updated.
    case usernameChanged(String)
}
