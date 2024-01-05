// MARK: - AppearanceAction

/// Actions handled by the `AppearanceProcessor`.
///
enum AppearanceAction: Equatable {
    /// The default dark mode theme was changed.
    case defaultDarkThemeChanged

    /// The default color theme was changed.
    case defaultThemeChanged

    /// The language option was tapped.
    case languageTapped

    /// Show website icons was toggled.
    case toggleShowWebsiteIcons(Bool)
}
