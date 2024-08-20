import SwiftUI

// MARK: - CreateAccountState

/// An object that defines the current state of a `CreateAccountView`.
///
struct CreateAccountState: Equatable {
    // MARK: Properties

    /// Whether passwords are visible in the view's text fields.
    var arePasswordsVisible: Bool = false

    /// Whether the continue button is enabled.
    var continueButtonEnabled: Bool {
        !passwordText.isEmpty
            && !retypePasswordText.isEmpty
            && passwordText.count >= requiredPasswordCount
            && passwordText == retypePasswordText
    }

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

    /// Whether the native create account feature flag is on.
    var nativeCreateAccountFeatureFlag: Bool = false

    /// The text in the password hint text field.
    var passwordHintText: String = ""

    /// The text in the master password text field.
    var passwordText: String = ""

    /// A scoring metric that represents the strength of the entered password. The score ranges from
    /// 0-4 (weak to strong password).
    var passwordStrengthScore: UInt8?

    /// The password visibility icon used in the view's text fields.
    var passwordVisibleIcon: ImageAsset {
        arePasswordsVisible ? Asset.Images.hidden : Asset.Images.visible
    }

    /// The required text count for the password strength.
    var requiredPasswordCount = 12

    /// The text in the re-type password text field.
    var retypePasswordText: String = ""
}
