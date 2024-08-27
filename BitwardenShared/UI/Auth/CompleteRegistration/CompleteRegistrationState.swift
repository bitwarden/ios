import SwiftUI

// MARK: - CompleteRegistrationState

/// An object that defines the current state of a `CompleteRegistrationView`.
///
struct CompleteRegistrationState: Equatable, Sendable {
    // MARK: Properties

    /// Whether passwords are visible in the view's text fields.
    var arePasswordsVisible: Bool = false

    /// Whether the continue button is enabled.
    var continueButtonEnabled: Bool {
        if nativeCreateAccountFeatureFlag {
            !passwordText.isEmpty
                && !retypePasswordText.isEmpty
                && passwordText.count >= requiredPasswordCount
        } else {
            true
        }
    }

    /// Token needed to complete registration
    var emailVerificationToken: String

    /// Whether the user came from email AppLink
    var fromEmail: Bool = false

    /// Whether the check for data breaches toggle is on.
    var isCheckDataBreachesToggleOn: Bool = true

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

    /// The region where the account should be created
    var region: RegionType?

    /// The required text count for the password strength.
    var requiredPasswordCount = Constants.minimumPasswordCharacters

    /// The text in the re-type password text field.
    var retypePasswordText: String = ""

    /// The email of the user that is creating the account.
    var userEmail: String

    /// A toast message to show in the view.
    var toast: Toast?

    // MARK: Computed Properties

    /// Text with user email in bold
    var headelineTextBoldEmail: String {
        Localizations.finishCreatingYourAccountForXBySettingAPassword("**\(userEmail)**")
    }
}
