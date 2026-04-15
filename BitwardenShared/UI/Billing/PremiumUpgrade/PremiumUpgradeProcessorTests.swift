import BitwardenKit
import BitwardenKitMocks
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
    let errorReporter: MockErrorReporter
    let subject: PremiumUpgradeProcessor

    // MARK: Initialization

    init() {
        billingService = MockBillingService()
        coordinator = MockCoordinator<BillingRoute, Void>()
        errorReporter = MockErrorReporter()
        let services = ServiceContainer.withMocks(
            billingService: billingService,
            errorReporter: errorReporter,
        )
        subject = PremiumUpgradeProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: PremiumUpgradeState(),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.upgradeNowTapped` logs the error and shows an error alert on failure.
    @Test
    func perform_upgradeNowTapped_failure() async throws {
        billingService.createCheckoutSessionThrowableError = BitwardenTestError.example

        await subject.perform(.upgradeNowTapped)

        #expect(billingService.createCheckoutSessionCallsCount == 1)
        #expect(subject.state.checkoutURL == nil)
        #expect(subject.state.isLoading == false)
        #expect(errorReporter.errors.first as? BitwardenTestError == .example)
        #expect(coordinator.errorAlertsShown.count == 1)
    }

    /// `perform(_:)` with `.upgradeNowTapped` shows an error when the service returns an invalid URL error.
    @Test
    func perform_upgradeNowTapped_invalidUrl() async throws {
        billingService.createCheckoutSessionThrowableError = BillingError.invalidCheckoutUrl

        await subject.perform(.upgradeNowTapped)

        #expect(subject.state.checkoutURL == nil)
        #expect(subject.state.isLoading == false)
        #expect(errorReporter.errors.first as? BillingError == .invalidCheckoutUrl)
        #expect(coordinator.errorAlertsShown.count == 1)
    }

    /// `perform(_:)` with `.upgradeNowTapped` sets the checkout URL on success.
    @Test
    func perform_upgradeNowTapped_success() async throws {
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingService.createCheckoutSessionReturnValue = expectedURL

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
