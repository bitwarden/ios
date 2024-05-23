import SwiftUI

// MARK: - CompleteRegistrationState

/// An object that defines the current state of a `CompleteRegistrationView`.
///
struct CompleteRegistrationState: Equatable {
    // MARK: Properties

    /// Whether passwords are visible in the view's text fields.
    var arePasswordsVisible: Bool = false

    /// Token needed to complete registration
    var emailVerificationToken: String

    /// Whether the check for data breaches toggle is on.
    var isCheckDataBreachesToggleOn: Bool = true

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

    /// The password visibility icon used in the view's text fields.
    var passwordVisibleIcon: ImageAsset {
        arePasswordsVisible ? Asset.Images.hidden : Asset.Images.visible
    }

    /// The region where the account should be created
    var region: RegionType?

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
