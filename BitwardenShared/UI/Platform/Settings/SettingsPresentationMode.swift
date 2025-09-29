// MARK: - SettingsPresentationMode

/// The presentation mode for the settings screen, based on where the settings are displayed from.
/// This is used to determine if specific UI elements are shown.
///
public enum SettingsPresentationMode: Equatable {
    /// The settings view is being shown prior to login/auth. This removes any user-specific
    /// settings, leaving device settings like flight recorder and language.
    case preLogin

    /// The settings view is being shown in the settings tab.
    case tab
}
