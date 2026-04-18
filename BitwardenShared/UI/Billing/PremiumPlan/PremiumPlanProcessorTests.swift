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

    /// `perform(_:)` with `.appeared` loads subscription with canceled status.
    @Test
    func perform_appeared_canceled() async {
        billingService.getPremiumPlanReturnValue = PremiumPlanResponseModel(
            available: true,
            legacyYear: nil,
            name: "Premium",
            seat: PlanPricingResponseModel(price: 12, provided: 1, stripePriceId: "seat"),
            storage: PlanPricingResponseModel(price: 4.80, provided: 1, stripePriceId: "storage"),
        )
        billingService.getSubscriptionReturnValue = PremiumSubscription(
            cadence: .annually,
            cancelAt: nil,
            canceled: Date(timeIntervalSince1970: 1_800_000_000),
            discount: 0,
            estimatedTax: 0,
            gracePeriod: nil,
            nextCharge: nil,
            seatsCost: 0,
            status: .canceled,
            storageCost: 0,
            suspension: nil,
        )

        await subject.perform(.appeared)

        #expect(subject.state.planStatus == .canceled)
        #expect(!subject.state.canceledDate.isEmpty)
    }

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

    /// `perform(_:)` with `.appeared` loads subscription with past due status.
    @Test
    func perform_appeared_pastDue() async {
        billingService.getPremiumPlanReturnValue = PremiumPlanResponseModel(
            available: true,
            legacyYear: nil,
            name: "Premium",
            seat: PlanPricingResponseModel(price: 12, provided: 1, stripePriceId: "seat"),
            storage: PlanPricingResponseModel(price: 4.80, provided: 1, stripePriceId: "storage"),
        )
        billingService.getSubscriptionReturnValue = PremiumSubscription(
            cadence: .annually,
            cancelAt: nil,
            canceled: nil,
            discount: 0,
            estimatedTax: 0,
            gracePeriod: 14,
            nextCharge: nil,
            seatsCost: 0,
            status: .pastDue,
            storageCost: 0,
            suspension: Date(timeIntervalSince1970: 1_803_219_691),
        )

        await subject.perform(.appeared)

        #expect(subject.state.planStatus == .pastDue)
        #expect(subject.state.gracePeriod.contains("14"))
        #expect(!subject.state.subscriptionEndDate.isEmpty)
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
        billingService.getSubscriptionReturnValue = PremiumSubscription(
            cadence: .annually,
            cancelAt: nil,
            canceled: nil,
            discount: 0,
            estimatedTax: 4.55,
            gracePeriod: nil,
            nextCharge: Date(timeIntervalSince1970: 1_803_219_691),
            seatsCost: 19.8,
            status: .active,
            storageCost: 0,
            suspension: nil,
        )

        await subject.perform(.appeared)

        #expect(billingService.getPremiumPlanCallsCount == 1)
        #expect(billingService.getSubscriptionCallsCount == 1)
        #expect(subject.state.planStatus == .active)
        #expect(subject.state.subscription != nil)
        #expect(subject.state.billingAmount.contains("$19.80"))
        #expect(subject.state.nextChargeAmount.contains("$24.35"))
        #expect(!subject.state.nextChargeDate.isEmpty)
        #expect(!subject.state.showStorageCost)
    }

    /// `receive(_:)` with `.cancelPremiumTapped` sets the URL to open.
    @Test
    func receive_cancelPremiumTapped() {
        subject.receive(.cancelPremiumTapped)

        #expect(subject.state.urlToOpen == ExternalLinksConstants.cancelPremiumPlan)
    }

    /// `receive(_:)` with `.clearUrl` clears the URL to open.
    @Test
    func receive_clearUrl() {
        subject.state.urlToOpen = ExternalLinksConstants.managePremiumPlan

        subject.receive(.clearUrl)

        #expect(subject.state.urlToOpen == nil)
    }

    /// `receive(_:)` with `.managePlanTapped` sets the URL to open.
    @Test
    func receive_managePlanTapped() {
        subject.receive(.managePlanTapped)

        #expect(subject.state.urlToOpen == ExternalLinksConstants.managePremiumPlan)
    }
}
