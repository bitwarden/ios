import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - BillingCoordinator

/// A coordinator that manages navigation for billing-related views.
///
class BillingCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasBillingService
        & HasEnvironmentService
        & HasErrorReportBuilder
        & HasErrorReporter

    // MARK: Properties

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `BillingCoordinator`.
    ///
    /// - Parameters:
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: BillingRoute, context: AnyObject?) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss()
        case .premiumPlan:
            showPremiumPlan()
        case .premiumUpgrade:
            showPremiumUpgrade()
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Shows the premium plan screen.
    ///
    private func showPremiumPlan() {
        let processor = PremiumPlanProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: PremiumPlanState(),
        )
        let view = PremiumPlanView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator?.push(viewController, navigationTitle: Localizations.plan)
    }

    /// Shows the premium upgrade screen.
    ///
    private func showPremiumUpgrade() {
        let processor = PremiumUpgradeProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: PremiumUpgradeState(),
        )
        let view = PremiumUpgradeView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}

// MARK: - HasErrorAlertServices

extension BillingCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
