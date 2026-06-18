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

    /// `navigate(to:)` with `.dismiss` pops the view when there's a view controller to pop.
    @Test
    func navigate_dismiss_pops() throws {
        stackNavigator.isPresenting = false
        stackNavigator.viewControllersToPop = [UIViewController()]

        subject.navigate(to: .dismiss)

        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .popped)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the view when presenting, using a completion handler.
    @Test
    func navigate_dismiss_dismisses() throws {
        stackNavigator.isPresenting = true

        subject.navigate(to: .dismiss)

        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.dismiss` after `.premiumUpgradeComplete` (vault context) dismisses
    /// PremiumUpgradeComplete and then dismisses the billing navController via the completion handler.
    @Test
    func navigate_dismiss_afterPremiumUpgradeComplete_vault() throws {
        stackNavigator.isEmpty = true
        subject.navigate(to: .premiumUpgrade)
        stackNavigator.actions.removeAll()

        stackNavigator.isPresenting = true
        subject.navigate(to: .premiumUpgradeComplete)
        stackNavigator.actions.removeAll()

        stackNavigator.isPresenting = true
        subject.navigate(to: .dismiss)

        // Should use dismissedWithCompletionHandler (dismiss PremiumUpgradeComplete +
        // fire onClose that dismisses the billing navController).
        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.dismiss` after `.premiumUpgradeComplete` (settings context) dismisses
    /// PremiumUpgradeComplete and then navigates to PremiumPlanView via the completion handler.
    @Test
    func navigate_dismiss_afterPremiumUpgradeComplete_settings() throws {
        stackNavigator.isEmpty = false
        subject.navigate(to: .premiumUpgrade)
        stackNavigator.actions.removeAll()

        stackNavigator.isPresenting = true
        subject.navigate(to: .premiumUpgradeComplete)
        stackNavigator.actions.removeAll()

        stackNavigator.isPresenting = true
        subject.navigate(to: .dismiss)

        // Completion fires synchronously: pop PremiumUpgradeView, push PremiumPlanView, then record dismissal.
        #expect(stackNavigator.actions.count == 3)
        #expect(stackNavigator.actions[0].type == .popped)
        #expect(stackNavigator.actions[1].type == .pushed)
        #expect(stackNavigator.actions[2].type == .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the navigator when it is the root (nothing to pop).
    /// This handles the vault upsell flow where the Premium upgrade view is the root of a presented
    /// navigation controller.
    @Test
    func navigate_dismiss_dismisses_when_root() throws {
        stackNavigator.isPresenting = false
        // viewControllersToPop is empty by default, so pop() returns nil

        subject.navigate(to: .dismiss)

        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .dismissed)
    }

    /// `navigate(to:)` with `.premiumUpgradeComplete` presents the Premium upgrade complete view.
    @Test
    func navigate_premiumUpgradeComplete() throws {
        subject.navigate(to: .premiumUpgradeComplete)

        #expect(stackNavigator.actions.count == 1)
        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .presented)
        #expect(action.view is PremiumUpgradeCompleteView)
    }

    /// `navigate(to:)` with `.premiumPlan` pushes the Premium plan view.
    @Test
    func navigate_premiumPlan() throws {
        subject.navigate(to: .premiumPlan(nil))

        #expect(stackNavigator.actions.count == 1)
        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .pushed)
    }

    /// `navigate(to:)` with `.premiumUpgrade` pushes the Premium upgrade view when the stack is non-empty
    /// (settings push flow) and hides the cancel button.
    @Test
    func navigate_premiumUpgrade_push() throws {
        stackNavigator.isEmpty = false
        subject.navigate(to: .premiumUpgrade)

        #expect(stackNavigator.actions.count == 1)
        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .pushed)
        let viewController = try #require(action.view as? UIHostingController<PremiumUpgradeView>)
        #expect(viewController.rootView.store.state.showCancelButton == false)
    }

    /// `navigate(to:)` with `.premiumUpgrade` replaces the stack when the navigator is empty
    /// (vault modal flow) and shows the cancel button.
    @Test
    func navigate_premiumUpgrade_replace() throws {
        stackNavigator.isEmpty = true
        subject.navigate(to: .premiumUpgrade)

        #expect(stackNavigator.actions.count == 1)
        let action = try #require(stackNavigator.actions.last)
        #expect(action.type == .replaced)
        let view = try #require(action.view as? PremiumUpgradeView)
        #expect(view.store.state.showCancelButton == true)
    }
}
