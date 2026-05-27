import BitwardenKit
import BitwardenResources
import Combine
import Foundation

// MARK: - CheckoutWebAuthSessionOutcome

/// The result of a Stripe checkout web authentication session.
///
enum CheckoutWebAuthSessionOutcome {
    /// The user dismissed the session without completing checkout.
    case canceled

    /// The session completed and Stripe returned a callback URL.
    case completed(callbackURL: URL)
}

// MARK: - PremiumUpgradeProcessorDelegate

/// A delegate for `PremiumUpgradeProcessor` to start a web authentication session for Stripe checkout.
///
@MainActor
protocol PremiumUpgradeProcessorDelegate: AnyObject {
    /// Starts an `ASWebAuthenticationSession` for the Stripe checkout and returns the outcome.
    ///
    /// - Parameter url: The Stripe checkout URL to open.
    /// - Returns: `.completed(callbackURL:)` if Stripe redirected back, or `.canceled` if the user dismissed.
    ///
    func performCheckoutWebAuthSession(url: URL) async -> CheckoutWebAuthSessionOutcome
}

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
        & HasErrorReporter

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<BillingRoute, Void>

    /// A delegate used to start the Stripe web authentication session.
    private weak var delegate: PremiumUpgradeProcessorDelegate?

    /// Cancellable for the premium checkout status subscription.
    private var premiumStatusChangedCancellable: AnyCancellable?

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a `PremiumUpgradeProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - delegate: The delegate used to start the Stripe web authentication session.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<BillingRoute, Void>,
        delegate: PremiumUpgradeProcessorDelegate?,
        services: Services,
        state: PremiumUpgradeState,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: PremiumUpgradeEffect) async {
        switch effect {
        case .appeared:
            state.isSelfHosted = await services.billingService.isSelfHosted()
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
        case .dismissBannerTapped:
            state.isBannerDismissed = true
        case .dismissPricingErrorBannerTapped:
            state.showPricingErrorBanner = false
        }
    }

    // MARK: Private Methods

    /// Fetches the premium plan price from the billing service and updates state.
    /// Shows the pricing error banner on failure.
    ///
    private func fetchPremiumPrice() async {
        defer { coordinator.hideLoadingOverlay() }
        coordinator.showLoadingOverlay(title: Localizations.loading)
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
                        await self.createCheckoutSession()
                    })
                case .syncing:
                    coordinator.showLoadingOverlay(title: Localizations.confirmingYourUpgrade)
                case .confirmed:
                    premiumStatusChangedCancellable = nil
                    coordinator.hideLoadingOverlay()
                    coordinator.navigate(to: .premiumUpgradeComplete)
                case .pending:
                    premiumStatusChangedCancellable = nil
                    coordinator.hideLoadingOverlay()
                    // Vault processors own the dismiss and alert for .pending.
                }
            }
    }

    /// Creates a checkout session, opens it via `ASWebAuthenticationSession`, and handles the result.
    ///
    private func createCheckoutSession() async {
        do {
            state.isLoading = true
            coordinator.showLoadingOverlay(title: Localizations.openingCheckout)
            let url = try await services.billingService.createCheckoutSession()
            coordinator.hideLoadingOverlay()
            state.isLoading = false
            subscribeToPremiumCheckoutStatus()
            switch await delegate?.performCheckoutWebAuthSession(url: url) {
            case .canceled, nil:
                coordinator.showAlert(.paymentNotReceivedYet {
                    await self.createCheckoutSession()
                })
            case let .completed(callbackURL):
                await handleCheckoutCallback(callbackURL)
            }
        } catch {
            coordinator.hideLoadingOverlay()
            state.isLoading = false
            services.errorReporter.log(error: error)
            coordinator.showAlert(.secureCheckoutDidntLoad {
                await self.createCheckoutSession()
            })
        }
    }

    /// Routes the Stripe callback URL to the appropriate billing service method.
    ///
    private func handleCheckoutCallback(_ callbackURL: URL) async {
        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        let result = components?.queryItems?.first(where: { item in
            item.name == BitwardenDeepLinkConstants.PremiumCheckoutResultQuery.parameterName
        })?.value

        if callbackURL.host == BitwardenDeepLinkConstants.premiumCheckoutResultHost,
           result == BitwardenDeepLinkConstants.PremiumCheckoutResultQuery.successValue {
            await services.billingService.premiumStatusChanged()
        } else {
            services.billingService.premiumCheckoutCanceled()
        }
    }
}
