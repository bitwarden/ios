import BitwardenKit
import BitwardenKitMocks
import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - PremiumUpgradeProcessorTests

@MainActor
struct PremiumUpgradeProcessorTests {
    // MARK: Properties

    let billingService: MockBillingService
    let coordinator: MockCoordinator<BillingRoute, Void>
    let environmentService: MockEnvironmentService
    let errorReporter: MockErrorReporter
    let subject: PremiumUpgradeProcessor

    // MARK: Initialization

    init() {
        billingService = MockBillingService()
        billingService.getPremiumPlanReturnValue = PremiumPlanResponseModel(
            available: true,
            legacyYear: nil,
            name: "Premium",
            seat: PlanPricingResponseModel(price: 19.80, provided: 0, stripePriceId: "premium-annually"),
            storage: PlanPricingResponseModel(price: 4, provided: 1, stripePriceId: "storage-annually"),
        )
        billingService.premiumCheckoutStatusPublisherReturnValue = PassthroughSubject<PremiumCheckoutStatus, Never>()
            .eraseToAnyPublisher()
        coordinator = MockCoordinator<BillingRoute, Void>()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        let services = ServiceContainer.withMocks(
            billingService: billingService,
            environmentService: environmentService,
            errorReporter: errorReporter,
        )
        subject = PremiumUpgradeProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: PremiumUpgradeState(),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` fetches the premium price and sets it in state on success.
    @Test
    func perform_appeared_fetchesPremiumPrice_success() async {
        environmentService.region = .unitedStates

        await subject.perform(.appeared)

        #expect(subject.state.premiumPrice != nil)
        #expect(subject.state.showPricingErrorBanner == false)
        #expect(billingService.getPremiumPlanCalled)
    }

    /// `perform(_:)` with `.appeared` shows the pricing error banner on failure.
    @Test
    func perform_appeared_fetchesPremiumPrice_failure() async {
        environmentService.region = .unitedStates
        billingService.getPremiumPlanThrowableError = BitwardenTestError.example

        await subject.perform(.appeared)

        #expect(subject.state.premiumPrice == nil)
        #expect(subject.state.showPricingErrorBanner == true)
        #expect(errorReporter.errors.first as? BitwardenTestError == .example)
    }

    /// `perform(_:)` with `.appeared` sets `isSelfHosted` to `false` when the environment is not self-hosted.
    @Test
    func perform_appeared_notSelfHosted() async {
        environmentService.region = .unitedStates

        await subject.perform(.appeared)

        #expect(subject.state.isSelfHosted == false)
    }

    /// `perform(_:)` with `.appeared` sets `isSelfHosted` to `true` when the environment is self-hosted.
    @Test
    func perform_appeared_selfHosted() async {
        environmentService.region = .selfHosted

        await subject.perform(.appeared)

        #expect(subject.state.isSelfHosted == true)
        #expect(!billingService.getPremiumPlanCalled)
    }

    /// `perform(_:)` with `.retryFetchPriceTapped` hides the banner and shows price on success.
    @Test
    func perform_retryFetchPriceTapped_success() async {
        subject.state.showPricingErrorBanner = true

        await subject.perform(.retryFetchPriceTapped)

        #expect(subject.state.premiumPrice != nil)
        #expect(subject.state.showPricingErrorBanner == false)
    }

    /// `perform(_:)` with `.retryFetchPriceTapped` hides then re-shows the banner on failure.
    @Test
    func perform_retryFetchPriceTapped_failure() async {
        subject.state.showPricingErrorBanner = true
        billingService.getPremiumPlanThrowableError = BitwardenTestError.example

        await subject.perform(.retryFetchPriceTapped)

        #expect(subject.state.premiumPrice == nil)
        #expect(subject.state.showPricingErrorBanner == true)
    }

    /// `perform(_:)` with `.upgradeNowTapped` logs the error and shows an error alert on failure.
    @Test
    func perform_upgradeNowTapped_failure() async throws {
        billingService.createCheckoutSessionThrowableError = BitwardenTestError.example

        await subject.perform(.upgradeNowTapped)

        #expect(billingService.createCheckoutSessionCallsCount == 1)
        #expect(subject.state.checkoutURL == nil)
        #expect(subject.state.isLoading == false)
        #expect(errorReporter.errors.first as? BitwardenTestError == .example)
        #expect(coordinator.alertShown.count == 1)
    }

    /// `perform(_:)` with `.upgradeNowTapped` shows an error when the service returns an invalid URL error.
    @Test
    func perform_upgradeNowTapped_invalidUrl() async throws {
        billingService.createCheckoutSessionThrowableError = BillingError.invalidCheckoutUrl

        await subject.perform(.upgradeNowTapped)

        #expect(subject.state.checkoutURL == nil)
        #expect(subject.state.isLoading == false)
        #expect(errorReporter.errors.first as? BillingError == .invalidCheckoutUrl)
        #expect(coordinator.alertShown.count == 1)
    }

    /// `perform(_:)` with `.upgradeNowTapped` sets the checkout URL on success.
    @Test
    func perform_upgradeNowTapped_success() async throws {
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingService.createCheckoutSessionReturnValue = expectedURL
        billingService.premiumCheckoutStatusPublisherReturnValue = PassthroughSubject<PremiumCheckoutStatus, Never>()
            .eraseToAnyPublisher()

        await subject.perform(.upgradeNowTapped)

        #expect(billingService.createCheckoutSessionCallsCount == 1)
        #expect(subject.state.checkoutURL == expectedURL)
        #expect(subject.state.isLoading == false)
    }

    /// `receive(_:)` with `.cancelTapped` navigates to dismiss.
    @Test
    func receive_cancelTapped() {
        subject.receive(.cancelTapped)

        #expect(coordinator.routes.last == .dismiss)
    }

    /// `receive(_:)` with `.dismissBannerTapped` sets `isBannerDismissed` to `true`.
    @Test
    func receive_dismissBannerTapped() {
        subject.state.isSelfHosted = true
        #expect(subject.state.showSelfHostedBanner == true)

        subject.receive(.dismissBannerTapped)

        #expect(subject.state.isBannerDismissed == true)
        #expect(subject.state.showSelfHostedBanner == false)
    }

    /// `receive(_:)` with `.dismissPricingErrorBannerTapped` hides the pricing error banner.
    @Test
    func receive_dismissPricingErrorBannerTapped() {
        subject.state.showPricingErrorBanner = true

        subject.receive(.dismissPricingErrorBannerTapped)

        #expect(subject.state.showPricingErrorBanner == false)
    }

    /// `receive(_:)` with `.clearURL` clears the checkout URL.
    @Test
    func receive_clearURL() {
        subject.state.checkoutURL = URL(string: "https://example.com")

        subject.receive(.clearURL)

        #expect(subject.state.checkoutURL == nil)
    }

    /// `receive(_:)` with `.urlOpenFailed` shows an error alert.
    @Test
    func receive_urlOpenFailed() async throws {
        subject.receive(.urlOpenFailed)

        try await waitForAsync { coordinator.errorAlertsShown.count == 1 }
        #expect(coordinator.errorAlertsShown.first as? BillingError == .unableToOpenCheckout)
    }
}
