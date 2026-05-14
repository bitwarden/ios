import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

@testable import BitwardenShared

// MARK: - PremiumUpgradeCompleteProcessorTests

@MainActor
struct PremiumUpgradeCompleteProcessorTests {
    // MARK: Properties

    let coordinator: MockCoordinator<BillingRoute, Void>
    let subject: PremiumUpgradeCompleteProcessor

    // MARK: Initialization

    init() {
        coordinator = MockCoordinator<BillingRoute, Void>()
        subject = PremiumUpgradeCompleteProcessor(coordinator: coordinator.asAnyCoordinator())
    }

    // MARK: Tests

    /// `receive(_:)` with `.closeTapped` navigates to dismiss.
    @Test
    func receive_closeTapped() {
        subject.receive(.closeTapped)

        #expect(coordinator.routes.last == .dismiss)
    }
}
