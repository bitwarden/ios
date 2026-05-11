import BitwardenKit
import Foundation

// MARK: - PremiumUpgradeCompleteProcessor

/// The processor used to manage state and handle actions for the `PremiumUpgradeCompleteView`.
///
final class PremiumUpgradeCompleteProcessor: StateProcessor<
    Void,
    PremiumUpgradeCompleteAction,
    Void,
> {
    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<BillingRoute, Void>

    // MARK: Initialization

    /// Initializes a `PremiumUpgradeCompleteProcessor`.
    ///
    /// - Parameter coordinator: The coordinator used for navigation.
    ///
    init(coordinator: AnyCoordinator<BillingRoute, Void>) {
        self.coordinator = coordinator
        super.init(state: ())
    }

    // MARK: Methods

    override func receive(_ action: PremiumUpgradeCompleteAction) {
        switch action {
        case .closeTapped:
            coordinator.navigate(to: .dismiss)
        }
    }
}
