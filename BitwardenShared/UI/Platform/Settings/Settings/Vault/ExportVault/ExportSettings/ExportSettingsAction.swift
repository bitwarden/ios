// MARK: - ExportSettingsAction

/// Actions handled by the `ExportSettingsProcessor`.
///
enum ExportSettingsAction {
    /// The export vault to another app button was tapped (Credential Exchange flow).
    case exportToAppTapped

    /// The export vault to a file button was tapped.
    case exportToFileTapped
}
