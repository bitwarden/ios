import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - PremiumPlanProcessor

/// The processor used to manage state and handle actions for the premium plan screen.
///
final class PremiumPlanProcessor: StateProcessor<
    PremiumPlanState,
    PremiumPlanAction,
    PremiumPlanEffect,
> {
    // MARK: Types

    typealias Services = HasBillingService
        & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<BillingRoute, Void>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `PremiumPlanProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<BillingRoute, Void>,
        services: Services,
        state: PremiumPlanState,
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: PremiumPlanEffect) async {
        switch effect {
        case .appeared:
            await loadPremiumPlan()
        }
    }

    override func receive(_ action: PremiumPlanAction) {
        switch action {
        case .cancelPremiumTapped:
            state.urlToOpen = ExternalLinksConstants.cancelPremiumPlan
        case .clearUrl:
            state.urlToOpen = nil
        case .managePlanTapped:
            state.urlToOpen = ExternalLinksConstants.managePremiumPlan
        }
    }

    // MARK: Private Methods

    /// Formats a decimal price as a US dollar currency string.
    ///
    /// - Parameter price: The price to format.
    /// - Returns: A formatted currency string (e.g. "$1.65").
    ///
    private func formatCurrency(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        // Currently this will only be used in the US market
        formatter.currencyCode = "USD"
        return formatter.string(from: price as NSDecimalNumber) ?? "$0.00"
    }

    /// Loads the premium plan details from the billing service and updates the state.
    ///
    private func loadPremiumPlan() async {
        do {
            let plan = try await services.billingService.getPremiumPlan()
            guard plan.available else {
                coordinator.showAlert(
                    .defaultAlert(
                        title: Localizations.anErrorHasOccurred,
                        message: Localizations.premiumPlanNotAvailable,
                    ),
                    onDismissed: { [weak self] in
                        self?.coordinator.navigate(to: .dismiss)
                    },
                )
                return
            }
            let monthlyBillingAmount = plan.seat.price / 12
            let monthlyStorageCost = plan.storage.price / 12
            state.billingAmount = "\(formatCurrency(monthlyBillingAmount)) \(Localizations.perMonth)"
            state.storageCost = formatCurrency(monthlyStorageCost)
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
