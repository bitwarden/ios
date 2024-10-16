import SwiftUI

// MARK: - CreateAccountState

/// An object that defines the current state of a `CreateAccountView`.
///
struct CreateAccountState: Equatable {
    // MARK: Properties

    /// Whether passwords are visible in the view's text fields.
    var arePasswordsVisible: Bool = false

    /// The text in the email text field.
    var emailText: String = ""

    /// Whether the check for data breaches toggle is on.
    var isCheckDataBreachesToggleOn: Bool = true

    /// Whether the terms and privacy toggle is on.
    var isTermsAndPrivacyToggleOn: Bool = false

    /// Whether the password is considered weak.
    var isWeakPassword: Bool {
        guard let passwordStrengthScore else { return false }
        return passwordStrengthScore < 3
    }

    /// The text in the password hint text field.
    var passwordHintText: String = ""

    /// The text in the master password text field.
    var passwordText: String = ""

    /// A scoring metric that represents the strength of the entered password. The score ranges from
    /// 0-4 (weak to strong password).
    var passwordStrengthScore: UInt8?

    /// The text in the re-type password text field.
    var retypePasswordText: String = ""
}
