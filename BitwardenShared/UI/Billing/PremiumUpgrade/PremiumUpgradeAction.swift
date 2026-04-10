// MARK: - PremiumUpgradeAction

/// Actions handled by the `PremiumUpgradeProcessor`.
///
enum PremiumUpgradeAction: Equatable {
    /// The cancel button was tapped.
    case cancelTapped

    /// Clear the checkout URL after it has been opened.
    case clearURL

    /// The checkout URL failed to open in the browser.
    case urlOpenFailed
}
