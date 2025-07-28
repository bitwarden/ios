import BitwardenResources

// MARK: - TwoFactorAuthMethod

/// An enum listing the types of two-factor authentication methods.
enum TwoFactorAuthMethod: Int {
    /// The user is using an authenticator app to provide the two-factor code.
    case authenticatorApp = 0

    /// The two-factor code is emailed to the user.
    case email = 1

    /// The Duo software handles the two-factor code.
    case duo = 2

    /// The YubiKey software handles the two-factor code.
    case yubiKey = 3

    /// The U2F software handles the two-factor code.
    case u2F = 4

    /// The two-factor code is cached and remembered.
    case remember = 5

    /// The Duo software through an organization handles the two-factor code.
    case duoOrganization = 6

    /// The Fido2WebApp software handles the two-factor code.
    case webAuthn = 7

    /// Let the user get a recovery code.
    case recoveryCode = -1

    // MARK: Properties

    /// The title of the method.
    var title: String {
        switch self {
        case .authenticatorApp:
            Localizations.authenticatorAppTitle
        case .duo,
             .duoOrganization:
            Localizations.duo
        case .email:
            Localizations.email
        case .webAuthn:
            Localizations.fido2AuthenticateWebAuthn
        case .recoveryCode:
            Localizations.recoveryCodeTitle
        case .yubiKey:
            Localizations.yubiKeyTitle
        default:
            ""
        }
    }

    /// The priority of each method (if multiple are supported, the one with the highest
    /// priority will be chosen as the default).
    var priority: Int {
        switch self {
        case .authenticatorApp:
            1
        case .email:
            0
        case .duo:
            2
        case .yubiKey:
            3
        case .duoOrganization:
            10
        case .webAuthn:
            4
        default:
            -1
        }
    }

    // MARK: Initialization

    /// Initialize a `TwoFactorAuthMethod` using a string of the the integer raw value.
    ///
    /// - Parameter value: The string representation of the integer raw value.
    ///
    init?(value: String) {
        guard let rawValue = Int(value) else { return nil }
        self.init(rawValue: rawValue)
    }

    // MARK: Methods

    /// The detailed instructions for the method.
    func details(_ email: String?) -> String {
        switch self {
        case .authenticatorApp:
            Localizations.enterVerificationCodeApp
        case .duo,
             .duoOrganization:
            Localizations.followTheStepsFromDuoToFinishLoggingIn
        case .email:
            Localizations.enterVerificationCodeEmail(email ?? "")
        case .yubiKey:
            Localizations.yubiKeyInstructionIos
        case .webAuthn:
            Localizations.continueToCompleteWebAuthnVerification
        default:
            ""
        }
    }
}

// MARK: - Identifiable

extension TwoFactorAuthMethod: Identifiable {
    var id: Int { rawValue }
}
