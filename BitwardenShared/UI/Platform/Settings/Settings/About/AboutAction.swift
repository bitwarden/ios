// MARK: - AboutAction

/// Actions handled by the `AboutProcessor`.
///
enum AboutAction: Equatable {
    /// The help center button was tapped.
    case helpCenterTapped

    /// The rate the app button was tapped.
    case rateTheAppTapped

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The submit crash logs toggle value changed.
    case toggleSubmitCrashLogs(Bool)

    /// The version was tapped.
    case versionTapped
}
