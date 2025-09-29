import BitwardenResources

// MARK: - ExportVaultState

/// An object that defines the current state of the `ExportVaultView`.
///
struct ExportVaultState: Equatable {
    // MARK: Properties

    /// Whether the ability to export one's personal vault has been disable by a policy.
    var disableIndividualVaultExport = false

    /// The currently selected file format type.
    var fileFormat: ExportFormatType = .json

    /// The file password confirmation text.
    var filePasswordConfirmationText = ""

    /// A scoring metric that represents the strength of the entered password. The score ranges from
    /// 0-4 (weak to strong password).
    var filePasswordStrengthScore: UInt8?

    /// The file password text.
    var filePasswordText = ""

    /// Whether the user has a master password.
    var hasMasterPassword = true

    /// Whether the file password field is visible.
    var isFilePasswordVisible = false

    /// Whether the master password/OTP field is visible.
    var isMasterPasswordOrOtpVisible = false

    /// Whether the send code button is disabled.
    var isSendCodeButtonDisabled = false

    /// The master password/OTP text.
    var masterPasswordOrOtpText = ""

    /// A toast message to show in the view.
    var toast: Toast?

    // MARK: Computed Properties

    /// The footer to display below the master password/OTP text field.
    var masterPasswordOrOtpFooter: String {
        hasMasterPassword ? Localizations.exportVaultMasterPasswordDescription : Localizations.confirmYourIdentity
    }

    /// The title for the master password/OTP text field.
    var masterPasswordOrOtpTitle: String {
        hasMasterPassword ? Localizations.masterPassword : Localizations.verificationCode
    }
}
