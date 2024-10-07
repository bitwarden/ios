// MARK: - AutoFillState

/// An object that defines the current state of the `AutoFillView`.
///
struct AutoFillState {
    // MARK: Properties

    /// The state of the badges in the settings tab.
    var badgeState: SettingsBadgeState?

    /// The default URI match type.
    var defaultUriMatchType: UriMatchType = .domain

    /// Whether or not the copy TOTP automatically toggle is on.
    var isCopyTOTPToggleOn: Bool = false

    // MARK: Computed Properties

    /// Whether the autofill action card should be shown.
    var shouldShowAutofillActionCard: Bool {
        guard let badgeState, badgeState.autofillSetupProgress != .complete else { return false }
        return true
    }
}
