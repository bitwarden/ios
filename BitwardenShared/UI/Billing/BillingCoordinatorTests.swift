import BitwardenKitMocks
import BitwardenResources
import SwiftUI
import Testing

@testable import BitwardenShared

// MARK: - BillingCoordinatorTests

@MainActor
struct BillingCoordinatorTests {
    // MARK: Properties

    let stackNavigator: MockStackNavigator
    let subject: BillingCoordinator

    // MARK: Initialization

    init() {
        stackNavigator = MockStackNavigator()
        subject = BillingCoordinator(
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator,
        )
    }

    // MARK: Tests

    /// `navigate(to:)` with `.dismiss` dismisses the view.
    @Test
    func navigate_dismiss() throws {
        subject.navigate(to: .dismiss)

        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .dismissed)
    }

    /// `navigate(to:)` with `.premiumPlan` pushes the premium plan view.
    @Test
    func navigate_premiumPlan() throws {
        subject.navigate(to: .premiumPlan)

        #expect(stackNavigator.actions.count == 1)
        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .pushed)
    }

    /// `navigate(to:)` with `.premiumUpgrade` replaces the stack with the premium upgrade view.
    @Test
    func navigate_premiumUpgrade() throws {
        subject.navigate(to: .premiumUpgrade)

        #expect(stackNavigator.actions.count == 1)
        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .replaced)
        #expect(action.view is PremiumUpgradeView)
    }
}
