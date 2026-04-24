import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
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
    let errorReporter: MockErrorReporter
    let premiumCheckoutStatusSubject: PassthroughSubject<PremiumCheckoutStatus, Never>
    let subject: PremiumUpgradeProcessor

    // MARK: Initialization

    init() {
        billingService = MockBillingService()
        premiumCheckoutStatusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()
        billingService.premiumCheckoutStatusPublisherReturnValue = premiumCheckoutStatusSubject
            .eraseToAnyPublisher()
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

    /// `perform(_:)` with `.upgradeNowTapped` logs the error and shows the retry alert on failure.
    @Test
    func perform_upgradeNowTapped_failure() async throws {
        billingService.createCheckoutSessionThrowableError = BitwardenTestError.example

        await subject.perform(.upgradeNowTapped)

        #expect(billingService.createCheckoutSessionCallsCount == 1)
        #expect(subject.state.checkoutURL == nil)
        #expect(subject.state.isLoading == false)
        #expect(coordinator.isLoadingOverlayShowing == false)
        #expect(errorReporter.errors.first as? BitwardenTestError == .example)
        #expect(coordinator.alertShown.last?.title == Localizations.secureCheckoutDidntLoad)
    }

    /// `perform(_:)` with `.upgradeNowTapped` shows the retry alert for an invalid URL error.
    @Test
    func perform_upgradeNowTapped_invalidUrl() async throws {
        billingService.createCheckoutSessionThrowableError = BillingError.invalidCheckoutUrl

        await subject.perform(.upgradeNowTapped)

        #expect(subject.state.checkoutURL == nil)
        #expect(coordinator.isLoadingOverlayShowing == false)
        #expect(errorReporter.errors.first as? BillingError == .invalidCheckoutUrl)
        #expect(coordinator.alertShown.last?.title == Localizations.secureCheckoutDidntLoad)
    }

    /// `perform(_:)` with `.upgradeNowTapped` retries when the user taps "Try again" after a failure.
    @Test
    func perform_upgradeNowTapped_failure_retrySucceeds() async throws {
        billingService.createCheckoutSessionThrowableError = BitwardenTestError.example
        await subject.perform(.upgradeNowTapped)

        let retryAlert = try #require(coordinator.alertShown.last)
        #expect(retryAlert.title == Localizations.secureCheckoutDidntLoad)

        billingService.createCheckoutSessionThrowableError = nil
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingService.createCheckoutSessionReturnValue = expectedURL
        await retryAlert.alertActions[1].handler?(retryAlert.alertActions[1], [])

        #expect(subject.state.checkoutURL == expectedURL)
        #expect(billingService.createCheckoutSessionCallsCount == 2)
    }

    /// `perform(_:)` with `.upgradeNowTapped` shows the "Opening checkout" loading overlay.
    @Test
    func perform_upgradeNowTapped_showsLoadingOverlay() async throws {
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingService.createCheckoutSessionReturnValue = expectedURL

        await subject.perform(.upgradeNowTapped)

        #expect(coordinator.loadingOverlaysShown.first?.title == Localizations.openingCheckout)
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
        #expect(coordinator.isLoadingOverlayShowing == false)
    }

    /// When the billing service emits `.confirmed`, the processor dismisses the modal.
    @Test
    func premiumCheckoutStatus_confirmed_dismisses() async throws {
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingService.createCheckoutSessionReturnValue = expectedURL
        await subject.perform(.upgradeNowTapped)

        premiumCheckoutStatusSubject.send(.confirmed)

        try await waitForAsync { coordinator.routes.last == .dismiss }
    }

    /// When the billing service emits `.pending`, the processor dismisses the modal.
    @Test
    func premiumCheckoutStatus_pending_dismisses() async throws {
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingService.createCheckoutSessionReturnValue = expectedURL
        await subject.perform(.upgradeNowTapped)

        premiumCheckoutStatusSubject.send(.pending)

        try await waitForAsync { coordinator.routes.last == .dismiss }
    }

    /// When the billing service emits `.canceled`, the processor shows the "Payment not received yet" alert.
    @Test
    func premiumCheckoutStatus_canceled_showsAlert() async throws {
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingService.createCheckoutSessionReturnValue = expectedURL
        await subject.perform(.upgradeNowTapped)

        premiumCheckoutStatusSubject.send(.canceled)

        try await waitForAsync { !coordinator.alertShown.isEmpty }
        #expect(coordinator.alertShown.last?.title == Localizations.paymentNotReceivedYet)
    }

    /// When the user taps "Go back" on the canceled alert, the checkout URL is reopened.
    @Test
    func premiumCheckoutStatus_canceled_goBack_reopensCheckoutURL() async throws {
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingService.createCheckoutSessionReturnValue = expectedURL
        await subject.perform(.upgradeNowTapped)
        subject.receive(.clearURL)

        premiumCheckoutStatusSubject.send(.canceled)
        try await waitForAsync { !coordinator.alertShown.isEmpty }

        let alert = try #require(coordinator.alertShown.last)
        await alert.alertActions[1].handler?(alert.alertActions[1], [])

        #expect(subject.state.checkoutURL == expectedURL)
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
