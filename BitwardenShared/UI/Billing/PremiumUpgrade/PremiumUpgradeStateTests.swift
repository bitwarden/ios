import BitwardenResources
import Testing

@testable import BitwardenShared

// MARK: - PremiumUpgradeStateTests

struct PremiumUpgradeStateTests {
    // MARK: Tests - premiumPrice

    /// `premiumPrice` returns the yearly seat price divided into a monthly amount.
    @Test
    func premiumPrice() {
        var state = PremiumUpgradeState()
        state.premiumSeatPrice = 19.80
        #expect(state.premiumPrice == "$1.65")
    }

    /// `premiumPrice` returns `nil` when the seat price hasn't been fetched.
    @Test
    func premiumPrice_nil() {
        let state = PremiumUpgradeState()
        #expect(state.premiumPrice == nil)
    }

    // MARK: Tests - priceCancelAnytimeAccessibilityLabel

    /// `priceCancelAnytimeAccessibilityLabel` uses "per month" and a comma instead of the raw
    /// "/" and "·" characters used in `priceCancelAnytimeText`.
    @Test
    func priceCancelAnytimeAccessibilityLabel() {
        var state = PremiumUpgradeState()
        state.premiumSeatPrice = 19.80
        let label = state.priceCancelAnytimeAccessibilityLabel
        #expect(label?.contains("$1.65") == true)
        #expect(label?.contains(Localizations.perMonthVoiceOver) == true)
        #expect(label?.contains("/") == false)
        #expect(label?.contains("·") == false)
    }

    /// `priceCancelAnytimeAccessibilityLabel` returns `nil` when the seat price hasn't been fetched.
    @Test
    func priceCancelAnytimeAccessibilityLabel_nil() {
        let state = PremiumUpgradeState()
        #expect(state.priceCancelAnytimeAccessibilityLabel == nil)
    }

    // MARK: Tests - priceCancelAnytimeText

    /// `priceCancelAnytimeText` combines the formatted price with the "/ month" cadence and
    /// "Cancel anytime" suffix.
    @Test
    func priceCancelAnytimeText() {
        var state = PremiumUpgradeState()
        state.premiumSeatPrice = 19.80
        let text = state.priceCancelAnytimeText
        #expect(text?.contains("$1.65") == true)
        #expect(text?.contains(Localizations.perMonth) == true)
    }

    /// `priceCancelAnytimeText` returns `nil` when the seat price hasn't been fetched.
    @Test
    func priceCancelAnytimeText_nil() {
        let state = PremiumUpgradeState()
        #expect(state.priceCancelAnytimeText == nil)
    }

    // MARK: Tests - showSelfHostedBanner

    /// `showSelfHostedBanner` is `true` when self-hosted and the banner hasn't been dismissed.
    @Test
    func showSelfHostedBanner_true() {
        var state = PremiumUpgradeState()
        state.isSelfHosted = true
        #expect(state.showSelfHostedBanner)
    }

    /// `showSelfHostedBanner` is `false` when the banner has been dismissed.
    @Test
    func showSelfHostedBanner_dismissed() {
        var state = PremiumUpgradeState()
        state.isSelfHosted = true
        state.isBannerDismissed = true
        #expect(!state.showSelfHostedBanner)
    }

    /// `showSelfHostedBanner` is `false` when not self-hosted.
    @Test
    func showSelfHostedBanner_notSelfHosted() {
        let state = PremiumUpgradeState()
        #expect(!state.showSelfHostedBanner)
    }
}
