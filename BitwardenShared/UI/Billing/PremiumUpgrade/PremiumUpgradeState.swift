import Foundation

// MARK: - PremiumUpgradeState

/// An object that defines the current state of the `PremiumUpgradeView`.
///
struct PremiumUpgradeState: Equatable {
    // MARK: Properties

    /// The checkout URL to open when the user taps the upgrade button.
    var checkoutURL: URL?

    /// Whether the self-hosted info banner has been dismissed.
    var isBannerDismissed = false

    /// Whether the view is loading the checkout session.
    var isLoading = false

    /// Whether the user is on a self-hosted server.
    var isSelfHosted = false

    /// The raw premium seat price. `nil` until successfully fetched from the API.
    var premiumSeatPrice: Decimal?

    /// Whether the pricing error banner is visible.
    var showPricingErrorBanner = false

    // MARK: Computed Properties

    /// The formatted monthly premium price string, or `nil` if the price hasn't been fetched yet.
    var premiumPrice: String? {
        premiumSeatPrice.flatMap { NumberFormatter.usdCurrency.string(from: NSDecimalNumber(decimal: $0 / 12)) }
    }

    /// Whether the self-hosted info banner should be shown.
    var showSelfHostedBanner: Bool {
        isSelfHosted && !isBannerDismissed
    }
}
