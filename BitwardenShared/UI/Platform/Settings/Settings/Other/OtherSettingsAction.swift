import BitwardenKit

// MARK: - OtherSettingsAction

/// Actions handled by the `OtherSettingsProcessor`.
///
enum OtherSettingsAction: Equatable {
    /// The clear clipboard value was changed.
    case clearClipboardValueChanged(ClearClipboardValue)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The allow sync on refresh toggle value changed.
    case toggleAllowSyncOnRefresh(Bool)

    /// The value of the Universal Clipboard toggle has changed.
    case toggleAllowUniversalClipboard(Bool)

    /// The connect to watch toggle value changed.
    case toggleConnectToWatch(Bool)

    /// The Siri & Shortcuts access toggle value changed.
    case toggleSiriAndShortcutsAccessToggleOn(Bool)
}
