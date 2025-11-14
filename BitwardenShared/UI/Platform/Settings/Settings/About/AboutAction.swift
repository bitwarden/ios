import BitwardenKit

// MARK: - AboutAction

/// Actions handled by the `AboutProcessor`.
///
enum AboutAction: Equatable {
    /// Clears the app review URL.
    case clearAppReviewURL

    /// The url has been opened so clear the value in the state.
    case clearURL

    /// An action for the Flight Recorder feature.
    case flightRecorder(FlightRecorderSettingsSectionAction)

    /// The help center button was tapped.
    case helpCenterTapped

    /// The learn about organizations button was tapped.
    case learnAboutOrganizationsTapped

    /// The privacy policy button was tapped.
    case privacyPolicyTapped

    /// The rate the app button was tapped.
    case rateTheAppTapped

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The submit crash logs toggle value changed.
    case toggleSubmitCrashLogs(Bool)

    /// The version was tapped.
    case versionTapped

    /// The web vault button was tapped.
    case webVaultTapped
}
