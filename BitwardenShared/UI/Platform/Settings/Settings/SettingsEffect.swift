/// Effects that can be processed by a `SettingsProcessor`.
///
enum SettingsEffect: Equatable {
    /// The view appeared so the initial data should be loaded.
    case appeared

    /// The user tapped the dismiss button on the Upgraded to Premium action card.
    case dismissUpgradedToPremiumActionCard

    /// The plan row was tapped.
    case planPressed
}
