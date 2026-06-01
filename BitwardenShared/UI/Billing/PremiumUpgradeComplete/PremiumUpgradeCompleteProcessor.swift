import BitwardenKit
import Foundation

// MARK: - PremiumUpgradeCompleteProcessor

/// The processor used to manage state and handle actions for the `PremiumUpgradeCompleteView`.
///
final class PremiumUpgradeCompleteProcessor: StateProcessor<
    Void,
    PremiumUpgradeCompleteAction,
    PremiumUpgradeCompleteEffect,
> {
    // MARK: Types

    typealias Services = HasBillingService

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<BillingRoute, Void>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a `PremiumUpgradeCompleteProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by this processor.
    ///
    init(
        coordinator: AnyCoordinator<BillingRoute, Void>,
        services: Services,
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: ())
    }

    // MARK: Methods

    override func perform(_ effect: PremiumUpgradeCompleteEffect) async {
        switch effect {
        case .appeared:
            // Clear the action card flag so the "Upgraded to Premium" card doesn't
            // appear on other tabs while this completion screen is already visible.
            await services.billingService.setUpgradedToPremiumActionCardDismissed()
        }
    }

    override func receive(_ action: PremiumUpgradeCompleteAction) {
        switch action {
        case .closeTapped:
            coordinator.navigate(to: .dismiss)
        }
    }
}
