import BitwardenKit

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
            break
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
}
