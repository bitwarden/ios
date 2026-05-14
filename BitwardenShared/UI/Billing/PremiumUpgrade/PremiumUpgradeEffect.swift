// MARK: - PremiumUpgradeEffect

/// Effects that can be processed by a `PremiumUpgradeProcessor`.
///
enum PremiumUpgradeEffect {
    /// The view appeared.
    case appeared

    /// The "Try again" button on the pricing error banner was tapped.
    case retryFetchPriceTapped

    /// The upgrade now button was tapped.
    case upgradeNowTapped
}
