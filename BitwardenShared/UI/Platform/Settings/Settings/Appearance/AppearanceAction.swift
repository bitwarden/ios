// MARK: - AppearanceAction

/// Actions handled by the `AppearanceProcessor`.
///
enum AppearanceAction: Equatable {
    /// The default dark mode theme was changed.
    case defaultDarkThemeChanged

    /// The language option was tapped.
    case languageTapped

    /// The default color theme was changed.
    case themeButtonTapped

    /// Show website icons was toggled.
    case toggleShowWebsiteIcons(Bool)
}
