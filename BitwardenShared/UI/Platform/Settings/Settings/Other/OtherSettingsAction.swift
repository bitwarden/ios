// MARK: - OtherSettingsAction

/// Actions handled by the `OtherSettingsProcessor`.
///
enum OtherSettingsAction: Equatable {
    /// The clear clipboard value was changed.
    case clearClipboardValueChanged(ClearClipboardValue)

    /// Clears the URL.
    case clearURL

    /// The give feedback button was pressed.
    case giveFeedbackPressed

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The allow sync on refresh toggle value changed.
    case toggleAllowSyncOnRefresh(Bool)

    /// The connect to watch toggle value changed.
    case toggleConnectToWatch(Bool)
}
