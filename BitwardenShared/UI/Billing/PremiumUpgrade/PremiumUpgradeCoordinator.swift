import BitwardenKit
import SwiftUI

// MARK: - PremiumUpgradeCoordinator

/// A coordinator that manages navigation for the premium upgrade view.
///
class PremiumUpgradeCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasBillingService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter

    // MARK: Properties

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `PremiumUpgradeCoordinator`.
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

    func navigate(to route: PremiumUpgradeRoute, context: AnyObject?) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss()
        }
    }

    func start() {
        showPremiumUpgrade()
    }

    // MARK: Private Methods

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

extension PremiumUpgradeCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
