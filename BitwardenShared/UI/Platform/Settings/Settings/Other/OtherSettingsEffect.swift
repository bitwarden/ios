// MARK: - OtherSettingsEffect

/// Effects handled by the `OtherSettingsProcessor`.
///
enum OtherSettingsEffect {
    /// Streams the last sync time.
    case streamLastSyncTime

    /// The sync button was tapped.
    case syncNow
}
