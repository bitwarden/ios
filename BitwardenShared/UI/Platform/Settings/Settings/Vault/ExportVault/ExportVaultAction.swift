// MARK: - ExportVaultAction

/// Actions handled by the `ExportVaultProcessor`.
enum ExportVaultAction: Equatable {
    /// Dismiss the sheet.
    case dismiss

    /// The export vault button was tapped.
    case exportVaultTapped

    /// The file format type was changed.
    case fileFormatTypeChanged(ExportFormatType)

    /// The password text changed.
    case passwordTextChanged(String)

    /// The password visibility was toggled.
    case togglePasswordVisibility(Bool)
}
