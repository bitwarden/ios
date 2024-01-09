// MARK: - AppearanceAction

/// Actions handled by the `AppearanceProcessor`.
///
enum AppearanceAction: Equatable {
    /// The default color theme was changed.
    case appThemeChanged(AppTheme)

    /// The language option was tapped.
    case languageTapped

    /// Show website icons was toggled.
    case toggleShowWebsiteIcons(Bool)
}
