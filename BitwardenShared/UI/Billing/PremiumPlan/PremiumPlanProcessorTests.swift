import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - PremiumPlanProcessorTests

@MainActor
struct PremiumPlanProcessorTests {
    // MARK: Properties

    let billingService: MockBillingService
    let coordinator: MockCoordinator<BillingRoute, Void>
    let errorReporter: MockErrorReporter
    let subject: PremiumPlanProcessor

    // MARK: Initialization

    init() {
        billingService = MockBillingService()
        coordinator = MockCoordinator<BillingRoute, Void>()
        errorReporter = MockErrorReporter()
        let services = ServiceContainer.withMocks(
            billingService: billingService,
            errorReporter: errorReporter,
        )
        subject = PremiumPlanProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: PremiumPlanState(),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` logs the error and shows an alert on failure.
    @Test
    func perform_appeared_failure() async {
        billingService.getPremiumPlanThrowableError = BitwardenTestError.example

        await subject.perform(.appeared)

        #expect(billingService.getPremiumPlanCallsCount == 1)
        #expect(errorReporter.errors.first as? BitwardenTestError == .example)
        #expect(coordinator.errorAlertsShown.count == 1)
        #expect(subject.state.subscription == nil)
    }

    /// `perform(_:)` with `.appeared` shows an alert and dismisses when the plan is not available.
    @Test
    func perform_appeared_planNotAvailable() async {
        billingService.getPremiumPlanReturnValue = PremiumPlanResponseModel(
            available: false,
            legacyYear: nil,
            name: "Premium",
            seat: PlanPricingResponseModel(price: 12, provided: 1, stripePriceId: "seat"),
            storage: PlanPricingResponseModel(price: 4.80, provided: 1, stripePriceId: "storage"),
        )

        await subject.perform(.appeared)

        #expect(billingService.getPremiumPlanCallsCount == 1)
        #expect(coordinator.alertShown.count == 1)
        #expect(
            coordinator.alertShown.first?.message == Localizations.atTheMomentPremiumPlanIsNotAvailableDescriptionLong,
        )
        #expect(subject.state.subscription == nil)

        coordinator.alertOnDismissed?()
        #expect(coordinator.routes.last == .dismiss)
    }

    /// `perform(_:)` with `.appeared` loads the subscription and updates state.
    @Test
    func perform_appeared_success() async {
        billingService.getPremiumPlanReturnValue = PremiumPlanResponseModel(
            available: true,
            legacyYear: nil,
            name: "Premium",
            seat: PlanPricingResponseModel(price: 12, provided: 1, stripePriceId: "seat"),
            storage: PlanPricingResponseModel(price: 4.80, provided: 1, stripePriceId: "storage"),
        )
        billingService.getSubscriptionReturnValue = .fixture(
            estimatedTax: 4.55,
            nextCharge: Date(timeIntervalSince1970: 1_803_219_691),
        )

        await subject.perform(.appeared)

        #expect(billingService.getPremiumPlanCallsCount == 1)
        #expect(billingService.getSubscriptionCallsCount == 1)
        #expect(subject.state.planStatus == .active)
        #expect(subject.state.subscription != nil)
        #expect(subject.state.billingAmount.contains("$19.80"))
        #expect(subject.state.nextChargeAmount.contains("USD"))
        #expect(subject.state.nextChargeAmount.contains("24.35"))
        #expect(!subject.state.nextChargeDate.isEmpty)
        #expect(!subject.state.showStorageCost)
    }

    /// `receive(_:)` with `.cancelPremiumTapped` shows the confirmation alert.
    @Test
    func receive_cancelPremiumTapped_showsConfirmationAlert() {
        subject.receive(.cancelPremiumTapped)

        #expect(coordinator.alertShown.count == 1)
        #expect(coordinator.alertShown.first?.title == Localizations.cancelPremium)
        #expect(coordinator.alertShown.first?.alertActions.count == 2)
        #expect(coordinator.alertShown.first?.alertActions.first?.title == Localizations.cancelNow)
        #expect(coordinator.alertShown.first?.alertActions.last?.title == Localizations.close)
    }

    /// `receive(_:)` with `.cancelPremiumTapped`, after confirming, fetches portal URL and sets state.
    @Test
    func receive_cancelPremiumTapped_confirmed_setsPortalUrl() async throws {
        let portalURL = URL(string: "https://billing.stripe.com/portal/session")!
        billingService.getPortalUrlReturnValue = portalURL
        subject.receive(.cancelPremiumTapped)

        let confirmAction = try #require(coordinator.alertShown.first?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        #expect(billingService.getPortalUrlCallsCount == 1)
        #expect(subject.state.urlToOpen == portalURL)
    }

    /// `receive(_:)` with `.cancelPremiumTapped`, after confirming, logs error and shows alert on failure.
    @Test
    func receive_cancelPremiumTapped_confirmed_serviceError() async throws {
        billingService.getPortalUrlThrowableError = BitwardenTestError.example
        subject.receive(.cancelPremiumTapped)

        let confirmAction = try #require(coordinator.alertShown.first?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        #expect(errorReporter.errors.first as? BitwardenTestError == .example)
        #expect(coordinator.errorAlertsShown.count == 1)
        #expect(subject.state.urlToOpen == nil)
    }

    /// `receive(_:)` with `.clearUrl` clears the URL to open.
    @Test
    func receive_clearUrl() {
        subject.state.urlToOpen = URL(string: "https://example.com")

        subject.receive(.clearUrl)

        #expect(subject.state.urlToOpen == nil)
    }

    /// `perform(_:)` with `.managePlanTapped` fetches portal URL and sets state.
    @Test
    func perform_managePlanTapped_setsPortalUrl() async {
        let portalURL = URL(string: "https://billing.stripe.com/portal/session")!
        billingService.getPortalUrlReturnValue = portalURL

        await subject.perform(.managePlanTapped)

        #expect(billingService.getPortalUrlCallsCount == 1)
        #expect(subject.state.urlToOpen == portalURL)
    }

    /// `perform(_:)` with `.managePlanTapped` logs error and shows alert on failure.
    @Test
    func perform_managePlanTapped_serviceError() async {
        billingService.getPortalUrlThrowableError = BitwardenTestError.example

        await subject.perform(.managePlanTapped)

        #expect(errorReporter.errors.first as? BitwardenTestError == .example)
        #expect(coordinator.errorAlertsShown.count == 1)
        #expect(subject.state.urlToOpen == nil)
    }
}
