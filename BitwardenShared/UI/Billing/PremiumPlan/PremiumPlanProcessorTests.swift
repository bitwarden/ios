import BitwardenKit
import BitwardenKitMocks
import Testing

@testable import BitwardenShared

// MARK: - PremiumPlanProcessorTests

@MainActor
struct PremiumPlanProcessorTests {
    // MARK: Properties

    let coordinator: MockCoordinator<BillingRoute, Void>
    let errorReporter: MockErrorReporter
    let subject: PremiumPlanProcessor

    // MARK: Initialization

    init() {
        coordinator = MockCoordinator<BillingRoute, Void>()
        errorReporter = MockErrorReporter()
        let services = ServiceContainer.withMocks(
            errorReporter: errorReporter,
        )
        subject = PremiumPlanProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: PremiumPlanState(),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` completes without error.
    @Test
    func perform_appeared() async {
        await subject.perform(.appeared)
    }

    /// `receive(_:)` with `.managePlanPressed` sets the URL to open.
    @Test
    func receive_managePlanPressed() {
        subject.receive(.managePlanPressed)

        #expect(subject.state.urlToOpen == ExternalLinksConstants.managePremiumPlan)
    }

    /// `receive(_:)` with `.cancelPremiumPressed` sets the URL to open.
    @Test
    func receive_cancelPremiumPressed() {
        subject.receive(.cancelPremiumPressed)

        #expect(subject.state.urlToOpen == ExternalLinksConstants.cancelPremiumPlan)
    }

    /// `receive(_:)` with `.clearUrl` clears the URL to open.
    @Test
    func receive_clearUrl() {
        subject.state.urlToOpen = ExternalLinksConstants.managePremiumPlan

        subject.receive(.clearUrl)

        #expect(subject.state.urlToOpen == nil)
    }
}
