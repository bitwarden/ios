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

    typealias Services = HasBillingService
        & HasEnvironmentService
        & HasErrorReporter

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<BillingRoute, Void>

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
        coordinator: AnyCoordinator<BillingRoute, Void>,
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
        case .appeared:
            state.isSelfHosted = services.environmentService.region == .selfHosted
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
        case .dismissBannerTapped:
            state.isBannerDismissed = true
        case .urlOpenFailed:
            Task {
                await coordinator.showErrorAlert(error: BillingError.unableToOpenCheckout)
            }
        }
    }

    // MARK: Private Methods

    /// Creates a checkout session by calling the billing service.
    ///
    private func createCheckoutSession() async {
        do {
            state.isLoading = true
            let url = try await services.billingService.createCheckoutSession()
            state.isLoading = false
            state.checkoutURL = url
        } catch {
            state.isLoading = false
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
