// MARK: - ExportVaultState

/// An object that defines the current state of the `ExportVaultView`.
///
struct ExportVaultState: Equatable {
    // MARK: Properties

    /// The currently selected file format type.
    var fileFormat: ExportFormatType = .json

    /// Whether the password field is visible.
    var isPasswordVisible = false

    /// The password text.
    var passwordText: String = ""
}
