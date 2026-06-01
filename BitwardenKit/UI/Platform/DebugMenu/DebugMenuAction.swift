// MARK: - DebugMenuAction

/// Actions that can be processed by a `DebugMenuProcessor`.
///
enum DebugMenuAction: Equatable {
    /// The copy user ID button was tapped.
    case copyUserID
    /// The dismiss button was tapped.
    case dismissTapped
    /// The generate crash button was tapped.
    case generateCrash
    /// The generate error report button was tapped.
    case generateErrorReport
    /// The generate SDK error report button was tapped.
    case generateSdkErrorReport
    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
