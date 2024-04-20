/// Actions that can be processed by a `SettingsProcessor`.
///
enum SettingsAction: Equatable {
    /// The default color theme was changed.
    case appThemeChanged(AppTheme)

    /// The url has been opened so clear the value in the state.
    case clearURL

    /// The export items button was tapped.
    case exportItemsTapped

    /// The help center button was tapped.
    case helpCenterTapped

    /// The language option was tapped.
    case languageTapped

    /// The privacy policy button was tapped.
    case privacyPolicyTapped

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The tutorial button was tapped
    case tutorialTapped

    /// The version was tapped.
    case versionTapped
}
