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

    /// The premium price to display. `nil` until successfully fetched from the API.
    var premiumPrice: String?

    /// Whether the pricing error banner is visible.
    var showPricingErrorBanner = false

    // MARK: Computed Properties

    /// Whether the self-hosted info banner should be shown.
    var showSelfHostedBanner: Bool {
        isSelfHosted && !isBannerDismissed
    }
}
