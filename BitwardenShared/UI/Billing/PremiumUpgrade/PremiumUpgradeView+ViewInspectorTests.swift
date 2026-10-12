// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - PremiumUpgradeViewTests

class PremiumUpgradeViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PremiumUpgradeState, PremiumUpgradeAction, PremiumUpgradeEffect>!
    var subject: PremiumUpgradeView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: PremiumUpgradeState())
        let store = Store(processor: processor)
        subject = PremiumUpgradeView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.cancelTapped` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .cancelTapped)
    }

    /// The cancel button is hidden when `showCancelButton` is `false`.
    @MainActor
    func test_cancelButton_hidden_whenShowCancelButtonFalse() throws {
        processor.state.showCancelButton = false
        XCTAssertThrowsError(try subject.inspect().findCancelToolbarButton())
    }

    /// Tapping the upgrade now button dispatches the `.upgradeNowTapped` effect.
    @MainActor
    func test_upgradeNowButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.upgradeToPremium)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .upgradeNowTapped)
    }

    /// The upgrade now button is disabled when the view is loading.
    @MainActor
    func test_upgradeNowButton_disabled_whenLoading() throws {
        processor.state.isLoading = true
        let button = try subject.inspect().find(asyncButton: Localizations.upgradeToPremium)
        XCTAssertTrue(button.isDisabled())
    }

    /// The upgrade now button is enabled when the view is not loading.
    @MainActor
    func test_upgradeNowButton_enabled_whenNotLoading() throws {
        processor.state.isLoading = false
        let button = try subject.inspect().find(asyncButton: Localizations.upgradeToPremium)
        XCTAssertFalse(button.isDisabled())
    }

    /// The pricing error banner is visible when `showPricingErrorBanner` is `true`.
    @MainActor
    func test_pricingErrorBanner_visible() throws {
        processor.state.showPricingErrorBanner = true
        let text = try subject.inspect().find(text: Localizations.pricingUnavailable)
        XCTAssertNotNil(text)
    }

    /// The pricing error banner is hidden when `showPricingErrorBanner` is `false`.
    @MainActor
    func test_pricingErrorBanner_hidden() throws {
        processor.state.showPricingErrorBanner = false
        XCTAssertThrowsError(
            try subject.inspect().find(text: Localizations.pricingUnavailable),
        )
    }

    /// Tapping the dismiss (X) button on the pricing error banner dispatches the correct action.
    @MainActor
    func test_pricingErrorBanner_dismissTapped() async throws {
        processor.state.showPricingErrorBanner = true
        let button = try subject.inspect().find(asyncButton: Localizations.close)
        try await button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPricingErrorBannerTapped)
    }

    /// Tapping "Try again" on the pricing error banner dispatches the correct effect.
    @MainActor
    func test_pricingErrorBanner_tryAgainTapped() async throws {
        processor.state.showPricingErrorBanner = true
        let button = try subject.inspect().find(asyncButton: Localizations.tryAgain)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .retryFetchPriceTapped)
    }

    /// The price section displays the price and the "Cancel anytime" suffix together, formatted
    /// from state.
    @MainActor
    func test_priceSection_displaysStateValue() throws {
        processor.state.premiumSeatPrice = 19.80
        let expectedText = Localizations.xCancelAnytime(
            Localizations.xAmountPerCadence("**$1.65**", Localizations.perMonth),
        )
        let text = try subject.inspect().find(text: expectedText)
        XCTAssertNotNil(text)
    }

    /// The price section is hidden when `premiumPrice` is `nil`.
    @MainActor
    func test_priceSection_hiddenWhenNil() throws {
        processor.state.premiumSeatPrice = nil
        let expectedText = Localizations.xCancelAnytime(
            Localizations.xAmountPerCadence("**$1.65**", Localizations.perMonth),
        )
        XCTAssertThrowsError(try subject.inspect().find(text: expectedText))
    }

    /// The headline is displayed.
    @MainActor
    func test_headline_displayed() throws {
        let text = try subject.inspect().find(text: Localizations.unlockAdvancedProtection)
        XCTAssertNotNil(text)
    }

    /// All 8 benefit rows are displayed.
    @MainActor
    func test_benefitRows_displayed() throws {
        XCTAssertNotNil(try subject.inspect().find(text: Localizations.breezeThrough2faWithBuiltInCodes))
        XCTAssertNotNil(try subject.inspect().find(text: Localizations.runReportsToFindRiskyPasswords))
        XCTAssertNotNil(try subject.inspect().find(text: Localizations.keepDocumentsSafeAndEncrypted))
        XCTAssertNotNil(try subject.inspect().find(text: Localizations.addATrustedEmergencyContact))
        XCTAssertNotNil(try subject.inspect().find(text: Localizations.identifyUnsecureWebsites))
        XCTAssertNotNil(try subject.inspect().find(text: Localizations.flagAccountsWithInactive2fa))
        XCTAssertNotNil(try subject.inspect().find(text: Localizations.shareFilesSecurelyWithAnyoneUsingSend))
        XCTAssertNotNil(try subject.inspect().find(text: Localizations.receive247PrioritySupport))
    }

    /// The self-hosted banner is visible when the user is on a self-hosted server.
    @MainActor
    func test_selfHostedBanner_visible() throws {
        processor.state.isSelfHosted = true
        let text = try subject.inspect().find(
            text: Localizations.toManageYourPremiumSubscriptionDescriptionLong,
        )
        XCTAssertNotNil(text)
    }

    /// The self-hosted banner is hidden when dismissed.
    @MainActor
    func test_selfHostedBanner_hidden_whenDismissed() throws {
        processor.state.isSelfHosted = true
        processor.state.isBannerDismissed = true
        XCTAssertThrowsError(
            try subject.inspect().find(
                text: Localizations.toManageYourPremiumSubscriptionDescriptionLong,
            ),
        )
    }

    /// The upgrade now button is hidden when the pricing error banner is showing.
    @MainActor
    func test_upgradeButton_hidden_whenPricingErrorBannerShowing() throws {
        processor.state.showPricingErrorBanner = true
        XCTAssertThrowsError(
            try subject.inspect().find(asyncButton: Localizations.upgradeToPremium),
        )
    }

    /// The upgrade button and Stripe footer are hidden when self-hosted.
    @MainActor
    func test_upgradeButton_hidden_whenSelfHosted() throws {
        processor.state.isSelfHosted = true
        XCTAssertThrowsError(
            try subject.inspect().find(asyncButton: Localizations.upgradeToPremium),
        )
    }
}
