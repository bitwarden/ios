import BitwardenKit
import BitwardenKitMocks
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

    /// `perform(_:)` with `.appeared` loads the premium plan and updates state.
    @Test
    func perform_appeared_success() async {
        billingService.getPremiumPlanReturnValue = PremiumPlanResponseModel(
            available: true,
            legacyYear: nil,
            name: "Premium",
            seat: PlanPricingResponseModel(
                price: 12,
                provided: 1,
                stripePriceId: "personal-premium-annually",
            ),
            storage: PlanPricingResponseModel(
                price: 4.80,
                provided: 1,
                stripePriceId: "personal-storage-gb-annually",
            ),
        )

        await subject.perform(.appeared)

        #expect(billingService.getPremiumPlanCallsCount == 1)
        #expect(subject.state.billingAmount.contains("$1.00"))
        #expect(subject.state.storageCost.contains("$0.40"))
    }

    /// `perform(_:)` with `.appeared` shows an alert and dismisses when the plan is not available.
    @Test
    func perform_appeared_planNotAvailable() async {
        billingService.getPremiumPlanReturnValue = PremiumPlanResponseModel(
            available: false,
            legacyYear: nil,
            name: "Premium",
            seat: PlanPricingResponseModel(
                price: 12,
                provided: 1,
                stripePriceId: "personal-premium-annually",
            ),
            storage: PlanPricingResponseModel(
                price: 4.80,
                provided: 1,
                stripePriceId: "personal-storage-gb-annually",
            ),
        )

        await subject.perform(.appeared)

        #expect(billingService.getPremiumPlanCallsCount == 1)
        #expect(coordinator.alertShown.count == 1)
        #expect(coordinator.alertShown.first?.message == Localizations.premiumPlanNotAvailable)
        #expect(subject.state.billingAmount == "")
        #expect(subject.state.storageCost == "")

        coordinator.alertOnDismissed?()
        #expect(coordinator.routes.last == .dismiss)
    }

    /// `perform(_:)` with `.appeared` logs the error and shows an alert on failure.
    @Test
    func perform_appeared_failure() async {
        billingService.getPremiumPlanThrowableError = BitwardenTestError.example

        await subject.perform(.appeared)

        #expect(billingService.getPremiumPlanCallsCount == 1)
        #expect(errorReporter.errors.first as? BitwardenTestError == .example)
        #expect(coordinator.errorAlertsShown.count == 1)
        #expect(subject.state.billingAmount == "")
        #expect(subject.state.storageCost == "")
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
