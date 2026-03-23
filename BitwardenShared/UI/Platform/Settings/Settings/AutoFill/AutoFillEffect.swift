// MARK: - AutoFillEffect

/// Effects emitted by the `AutoFillView`.
///
enum AutoFillEffect: Equatable {
    /// The user tapped the dismiss button on the set up autofill action card.
    case dismissSetUpAutofillActionCard

    /// The view appears and the initial values should be fetched.
    case fetchSettingValues

    /// The user tapped the get started/turn on button on the set up autofill action card.
    case setUpAutofill

    /// Stream the state of the badges in the settings tab.
    case streamSettingsBadge
}
