// MARK: - ExportVaultAction

/// Actions handled by the `ExportVaultProcessor`.
enum ExportVaultAction: Equatable {
    /// Dismiss the sheet.
    case dismiss

    /// The export vault button was tapped.
    case exportVaultTapped

    /// The file format type was changed.
    case fileFormatTypeChanged(ExportFormatType)

    /// The file password text changed.
    case filePasswordTextChanged(String)

    /// The file password confirmation text changed.
    case filePasswordConfirmationTextChanged(String)

    /// The master password/OTP text changed.
    case masterPasswordOrOtpTextChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The file password visibility was toggled.
    case toggleFilePasswordVisibility(Bool)

    /// The master password/OTP visibility was toggled.
    case toggleMasterPasswordOrOtpVisibility(Bool)
}
