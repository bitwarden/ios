import BitwardenResources
import Foundation

// MARK: - TwoFactorAuthState

/// The state used to present the `TwoFactorAuthView`.
struct TwoFactorAuthState: Equatable, Sendable {
    // MARK: Properties

    /// The selected authenticator method.
    var authMethod: TwoFactorAuthMethod = .email

    /// The auth method data returned by the API.
    var authMethodsData = AuthMethodsData()

    /// The available auth methods for the user.
    var availableAuthMethods = [TwoFactorAuthMethod]()

    /// Whether the continue button is enabled.
    var continueEnabled = false

    /// Whether the flow is to verify the device or not
    var deviceVerificationRequired: Bool = false

    /// The text to display in the detailed instructions.
    var detailsText: String {
        if deviceVerificationRequired {
            return Localizations.weDontRecognizeThisDeviceEnterTheCodeSentToYourEmailDescriptionLong
        }
        return authMethod.details(displayEmail)
    }

    /// The email address that should be displayed in the instructions of the email method.
    var displayEmail = ""

    /// The user's email address.
    var email = ""

    /// Whether the remember me toggle is on.
    var isRememberMeOn = false

    /// User organization idenfier if came from SSO flow
    var orgIdentifier: String?

    /// The text to display in the detailed instructions.
    var titleText: String {
        if deviceVerificationRequired {
            return Localizations.verifyYourIdentity
        }
        return authMethod.title
    }

    /// A toast message to show in the view.
    var toast: Toast?

    /// The method used to unlock the vault after two-factor completes successfully.
    var unlockMethod: TwoFactorUnlockMethod?

    /// The url to open in the device's web browser.
    var url: URL?

    /// The verification code text.
    var verificationCode = ""

    // MARK: Computed Properties

    /// The image asset to display for the selected authentication method.
    var authMethodImageAsset: ImageAsset? {
        switch authMethod {
        case .email:
            Asset.Images.Illustrations.emailOtp
        case .authenticatorApp:
            Asset.Images.Illustrations.authenticatorApp
        default:
            nil
        }
    }

    /// The image asset to display for the auth method.
    var detailImageAsset: ImageAsset? {
        switch authMethod {
        case .yubiKey:
            Asset.Images.Illustrations.yubikey
        default:
            nil
        }
    }
}
