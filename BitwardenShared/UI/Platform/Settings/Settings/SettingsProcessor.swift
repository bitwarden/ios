import BitwardenKit
import BitwardenResources

// MARK: - SettingsProcessorDelegate

/// A delegate of `SettingsProcessor` that is notified when the settings tab badge needs to be updated.
///
@MainActor
protocol SettingsProcessorDelegate: AnyObject {
    /// Called when the settings tab badge needs to be updated.
    ///
    /// - Parameter badgeValue: The value to display in the settings tab badge.
    ///
    func updateSettingsTabBadge(_ badgeValue: String?)
}

// MARK: - SettingsProcessor

/// The processor used to manage state and handle actions for the settings screen.
///
final class SettingsProcessor: StateProcessor<SettingsState, SettingsAction, SettingsEffect> {
    // MARK: Types

    typealias Services = HasBillingService
        & HasConfigService
        & HasErrorReporter
        & HasStateService
        & HasStorefrontService
        & HasVaultRepository

    // MARK: Private Properties

    /// The task used to update the tab's badge count.
    private(set) var badgeUpdateTask: Task<Void, Never>?

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// A delegate of the processor that is notified when the settings tab badge needs to be updated.
    private weak var delegate: SettingsProcessorDelegate?

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `SettingsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - delegate: A delegate of the processor that is notified when the settings tab badge needs
    ///     to be updated.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        delegate: SettingsProcessorDelegate,
        services: Services,
        state: SettingsState,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)

        // Kick off this task in init so that the tab bar badge will be updated immediately when
        // the tab bar is shown vs once the user navigates to the settings tab. Badge updates
        // require an active account, so this is skipped in pre-login presentation mode.
        if state.presentationMode == .tab {
            badgeUpdateTask = Task { @MainActor [weak self] in
                do {
                    guard let publisher = try await self?.services.stateService.settingsBadgePublisher() else { return }
                    for await badgeState in publisher.values {
                        self?.delegate?.updateSettingsTabBadge(badgeState.badgeValue)
                        self?.state.badgeState = badgeState
                    }
                } catch {
                    self?.services.errorReporter.log(error: error)
                }
            }
        }
    }

    deinit {
        badgeUpdateTask?.cancel()
    }

    // MARK: Methods

    override func perform(_ effect: SettingsEffect) async {
        switch effect {
        case .appeared:
            guard state.presentationMode == .tab else { return }
            let featureEnabled = await services.configService
                .getFeatureFlag(.premiumUpgradePath, defaultValue: false)
            let hasPremium = await services.vaultRepository.doesActiveAccountHavePremium()
            let isSelfHosted = await services.billingService.isSelfHosted()
            let isUSStorefront = await services.storefrontService.isUSStorefront()
            state.hasPremium = hasPremium
            state.showPlanRow = featureEnabled && !isSelfHosted && isUSStorefront
            state.shouldShowUpgradedToPremiumActionCard = await services.billingService
                .shouldShowUpgradedToPremiumActionCard()
        case .dismissUpgradedToPremiumActionCard:
            state.shouldShowUpgradedToPremiumActionCard = false
            await services.billingService.setUpgradedToPremiumActionCardDismissed()
        case .planPressed:
            await navigateToPlan()
        }
    }

    override func receive(_ action: SettingsAction) {
        switch action {
        case .aboutPressed:
            coordinator.navigate(to: .about)
        case .accountSecurityPressed:
            coordinator.navigate(to: .accountSecurity)
        case .appearancePressed:
            coordinator.navigate(to: .appearance)
        case .autoFillPressed:
            coordinator.navigate(to: .autoFill)
        case .clearUrl:
            state.url = nil
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case .learnMoreAboutPremium:
            state.url = ExternalLinksConstants.learnMoreAboutPremium
            state.shouldShowUpgradedToPremiumActionCard = false
            Task { await services.billingService.setUpgradedToPremiumActionCardDismissed() }
        case .otherPressed:
            coordinator.navigate(to: .other)
        case .vaultPressed:
            coordinator.navigate(to: .vault)
        }
    }

    // MARK: Private Methods

    /// Navigates to the appropriate plan screen based on the user's premium and subscription status.
    ///
    private func navigateToPlan() async {
        guard !state.hasPremium else {
            coordinator.navigate(to: .premiumPlan(nil))
            return
        }

        defer { coordinator.hideLoadingOverlay() }
        coordinator.showLoadingOverlay(title: Localizations.loading)

        do {
            let subscription = try await services.billingService.getSubscription()
            if subscription.status.isTroubleState {
                coordinator.navigate(to: .premiumPlan(subscription))
            } else {
                coordinator.navigate(to: .premiumUpgrade)
            }
        } catch is GetSubscriptionRequestError {
            coordinator.navigate(to: .premiumUpgrade)
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
