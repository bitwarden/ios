import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - PremiumPlanProcessor

/// The processor used to manage state and handle actions for the Premium plan screen.
///
final class PremiumPlanProcessor: StateProcessor<
    PremiumPlanState,
    PremiumPlanAction,
    PremiumPlanEffect,
> {
    // MARK: Types

    typealias Services = HasBillingService
        & HasEnvironmentService
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
        case .managePlanTapped:
            showManageSubscriptionAlert()
        case .tryAgainTapped:
            await loadPremiumPlan()
        }
    }

    override func receive(_ action: PremiumPlanAction) {
        switch action {
        case .cancelPremiumTapped:
            showCancelConfirmation()
        case .clearUrl:
            state.urlToOpen = nil
        }
    }

    // MARK: Private Methods

    /// Shows the "Continue to web app?" alert for managing the subscription plan.
    ///
    private func showManageSubscriptionAlert() {
        coordinator.showAlert(
            .manageSubscriptionPlanAlert { [weak self] in
                self?.state.urlToOpen = self?.services.environmentService.manageSubscriptionURL
            },
        )
    }

    /// Fetches the portal URL from the billing service and sets it on state.
    ///
    private func openPortalUrl() async {
        defer { coordinator.hideLoadingOverlay() }
        coordinator.showLoadingOverlay(title: Localizations.loading)

        do {
            let url = try await services.billingService.getPortalUrl()
            state.urlToOpen = url
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }

    /// Shows the cancel Premium confirmation alert.
    ///
    private func showCancelConfirmation() {
        coordinator.showAlert(
            Alert(
                title: Localizations.continueToStripe,
                message: Localizations.youllBeTakenToStripeToManageYourSubscriptionCancellation,
                alertActions: [
                    AlertAction(title: Localizations.cancel, style: .cancel),
                    AlertAction(title: Localizations.continue, style: .default) { [weak self] _ in
                        guard let self else { return }
                        await openPortalUrl()
                    },
                ],
            ),
        )
    }

    /// Loads the Premium plan details from the billing service and updates the state.
    ///
    private func loadPremiumPlan() async {
        let existingSubscription = state.loadingState.data
        state.loadingState = .loading(existingSubscription)

        do {
            let plan = try await services.billingService.getPremiumPlan()
            guard plan.available else {
                state.loadingState = .error(errorMessage: "")
                return
            }
            let subscription: PremiumSubscription = if let existing = existingSubscription {
                existing
            } else {
                try await services.billingService.getSubscription()
            }
            state.loadingState = .data(subscription)
            state.planStatus = subscription.status
        } catch {
            services.errorReporter.log(error: error)
            state.loadingState = .error(errorMessage: error.localizedDescription)
        }
    }
}
