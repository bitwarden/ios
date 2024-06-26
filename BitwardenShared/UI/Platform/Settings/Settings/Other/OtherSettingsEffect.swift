// MARK: - OtherSettingsEffect

/// Effects handled by the `OtherSettingsProcessor`.
///
enum OtherSettingsEffect {
    /// Load the initial values for the view.
    case loadInitialValues

    /// Streams the last sync time.
    case streamLastSyncTime

    /// The sync button was tapped.
    case syncNow
}
