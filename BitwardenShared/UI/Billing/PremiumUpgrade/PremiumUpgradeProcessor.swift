import BitwardenKit
import BitwardenResources
import Combine
import Foundation

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

    /// The last checkout URL returned by the billing service, used to reopen Stripe if canceled.
    private var lastCheckoutURL: URL?

    /// Cancellable for the premium checkout status subscription.
    private var premiumStatusChangedCancellable: AnyCancellable?

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
            if !state.isSelfHosted {
                await fetchPremiumPrice()
            }
        case .retryFetchPriceTapped:
            state.showPricingErrorBanner = false
            await fetchPremiumPrice()
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
        case .dismissPricingErrorBannerTapped:
            state.showPricingErrorBanner = false
        case .urlOpenFailed:
            Task {
                await coordinator.showErrorAlert(error: BillingError.unableToOpenCheckout)
            }
        }
    }

    // MARK: Private Methods

    /// Fetches the premium plan price from the billing service and updates state.
    /// Shows the pricing error banner on failure.
    ///
    private func fetchPremiumPrice() async {
        do {
            let plan = try await services.billingService.getPremiumPlan()
            state.premiumSeatPrice = plan.seat.price
            state.showPricingErrorBanner = false
        } catch {
            services.errorReporter.log(error: error)
            state.showPricingErrorBanner = true
        }
    }

    /// Subscribes to premium checkout status updates and reacts accordingly.
    ///
    private func subscribeToPremiumCheckoutStatus() {
        premiumStatusChangedCancellable = services.billingService
            .premiumCheckoutStatusPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .canceled:
                    coordinator.showAlert(.paymentNotReceivedYet {
                        self.state.checkoutURL = self.lastCheckoutURL
                    })
                case .confirmed,
                     .pending,
                     .syncing:
                    // VaultListProcessor owns the dismiss and all post-dismiss actions
                    // via DismissAction for each of these states.
                    premiumStatusChangedCancellable = nil
                }
            }
    }

    /// Creates a checkout session by calling the billing service.
    ///
    private func createCheckoutSession() async {
        do {
            state.isLoading = true
            coordinator.showLoadingOverlay(title: Localizations.openingCheckout)
            let url = try await services.billingService.createCheckoutSession()
            coordinator.hideLoadingOverlay()
            state.isLoading = false
            lastCheckoutURL = url
            subscribeToPremiumCheckoutStatus()
            state.checkoutURL = url
        } catch {
            coordinator.hideLoadingOverlay()
            state.isLoading = false
            services.errorReporter.log(error: error)
            coordinator.showAlert(.secureCheckoutDidntLoad {
                await self.createCheckoutSession()
            })
        }
    }
}
