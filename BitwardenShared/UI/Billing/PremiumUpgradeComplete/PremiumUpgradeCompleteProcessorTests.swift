import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - PremiumUpgradeCompleteProcessorTests

@MainActor
struct PremiumUpgradeCompleteProcessorTests {
    // MARK: Properties

    let billingService: MockBillingService
    let coordinator: MockCoordinator<BillingRoute, Void>
    let subject: PremiumUpgradeCompleteProcessor

    // MARK: Initialization

    init() {
        billingService = MockBillingService()
        coordinator = MockCoordinator<BillingRoute, Void>()
        subject = PremiumUpgradeCompleteProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(billingService: billingService),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` dismisses the upgraded to Premium action card.
    @Test
    func perform_appeared_dismissesUpgradedToPremiumActionCard() async {
        await subject.perform(.appeared)

        #expect(billingService.setUpgradedToPremiumActionCardDismissedCallsCount == 1)
    }

    /// `receive(_:)` with `.closeTapped` navigates to dismiss.
    @Test
    func receive_closeTapped() {
        subject.receive(.closeTapped)

        #expect(coordinator.routes.last == .dismiss)
    }
}
