import BitwardenKit

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

    typealias Services = HasConfigService
        & HasEnvironmentService
        & HasErrorReporter
        & HasStateService
        & HasVaultRepository

    // MARK: Private Properties

    /// The task used to update the tab's badge count.
    private var badgeUpdateTask: Task<Void, Never>?

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
        // the tab bar is shown vs once the user navigates to the settings tab.
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

    deinit {
        badgeUpdateTask?.cancel()
    }

    // MARK: Methods

    override func perform(_ effect: SettingsEffect) async {
        switch effect {
        case .appeared:
            let featureEnabled = await services.configService
                .getFeatureFlag(.premiumUpgradePath, defaultValue: false)
            let hasPremium = await services.vaultRepository.doesActiveAccountHavePremium()
            let isSelfHosted = services.environmentService.region == .selfHosted
            state.showPlanRow = featureEnabled && hasPremium && !isSelfHosted
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
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case .otherPressed:
            coordinator.navigate(to: .other)
        case .planPressed:
            coordinator.navigate(to: .premiumPlan)
        case .vaultPressed:
            coordinator.navigate(to: .vault)
        }
    }
}
