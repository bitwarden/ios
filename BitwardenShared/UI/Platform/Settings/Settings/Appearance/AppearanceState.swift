// MARK: - AppearanceState

/// An object that defines the current state of the `AppearanceView`.
///
struct AppearanceState {
    /// The selected app theme.
    var appTheme: ThemeOption = .default

    /// Whether or not the show website icons toggle is on.
    var isShowWebsiteIconsToggleOn: Bool = false
}
