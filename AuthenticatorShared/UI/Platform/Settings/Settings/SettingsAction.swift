import BitwardenKit

/// Actions that can be processed by a `SettingsProcessor`.
///
enum SettingsAction: Equatable {
    /// The default color theme was changed.
    case appThemeChanged(AppTheme)

    /// The backup button was tapped.
    case backupTapped

    /// The url has been opened so clear the value in the state.
    case clearURL

    /// The default save option was changed.
    case defaultSaveChanged(DefaultSaveOption)

    /// The export items button was tapped.
    case exportItemsTapped

    /// An action for the Flight Recorder feature.
    case flightRecorder(FlightRecorderSettingsSectionAction)

    /// The help center button was tapped.
    case helpCenterTapped

    /// The import items button was tapped.
    case importItemsTapped

    /// The language option was tapped.
    case languageTapped

    /// The privacy policy button was tapped.
    case privacyPolicyTapped

    /// The sync with bitwarden app button was tapped.
    case syncWithBitwardenAppTapped

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The tutorial button was tapped
    case tutorialTapped

    /// The version was tapped.
    case versionTapped
}
