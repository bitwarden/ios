import BitwardenKit

// MARK: - PremiumUpgradeProcessor

/// The processor used to manage state and handle actions for the `PremiumUpgradeView`.
///
final class PremiumUpgradeProcessor: StateProcessor<
    PremiumUpgradeState,
    PremiumUpgradeAction,
    PremiumUpgradeEffect,
> {
    // MARK: Types

    typealias Services = HasBillingAPIService
        & HasErrorReporter

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<PremiumUpgradeRoute, Void>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a `PremiumUpgradeProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<PremiumUpgradeRoute, Void>,
        services: Services,
        state: PremiumUpgradeState,
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: PremiumUpgradeEffect) async {
        switch effect {
        case .upgradeNowTapped:
            await createCheckoutSession()
        }
    }

    override func receive(_ action: PremiumUpgradeAction) {
        switch action {
        case .cancelTapped:
            coordinator.navigate(to: .dismiss)
        case .clearURL:
            state.checkoutURL = nil
        }
    }

    // MARK: Private Methods

    /// Creates a checkout session by calling the billing API.
    ///
    private func createCheckoutSession() async {
        defer { state.isLoading = false }
        do {
            state.isLoading = true
            let response = try await services.billingAPIService.createCheckoutSession()
            state.checkoutURL = response.checkoutSessionUrl
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
