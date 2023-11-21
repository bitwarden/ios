// MARK: - OtherSettingsAction

/// Actions handled by the `OtherSettingsProcessor`.
///
enum OtherSettingsAction {
    /// The allow sync on refresh toggle value changed.
    case toggleAllowSyncOnRefresh(Bool)

    /// The connect to watch toggle value changed.
    case toggleConnectToWatch(Bool)
}
