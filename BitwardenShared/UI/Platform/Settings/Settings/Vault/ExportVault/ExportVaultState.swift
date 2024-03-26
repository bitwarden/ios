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

    /// Whether the file password field is visible.
    var isFilePasswordVisible = false

    /// Whether the master password field is visible.
    var isMasterPasswordVisible = false

    /// The master password text.
    var masterPasswordText = ""
}
