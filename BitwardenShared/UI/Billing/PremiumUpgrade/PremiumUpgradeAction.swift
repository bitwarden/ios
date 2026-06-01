// MARK: - PremiumUpgradeAction

/// Actions handled by the `PremiumUpgradeProcessor`.
///
enum PremiumUpgradeAction: Equatable {
    /// The cancel button was tapped.
    case cancelTapped

    /// The self-hosted info banner dismiss button was tapped.
    case dismissBannerTapped

    /// The pricing error banner dismiss (X) button was tapped.
    case dismissPricingErrorBannerTapped
}
