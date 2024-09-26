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
final class SettingsProcessor: StateProcessor<SettingsState, SettingsAction, Void> {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasStateService

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
        state: SettingsState
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)

        // Kick off this task in init so that the tab bar badge will be updated immediately when
        // the tab bar is shown vs once the user navigates to the settings tab.
        badgeUpdateTask = Task { @MainActor [weak self] in
            guard await self?.services.configService.getFeatureFlag(.nativeCreateAccountFlow) == true else { return }
            do {
                guard let publisher = try await self?.services.stateService.settingsBadgePublisher() else { return }
                for await badgeValue in publisher.values {
                    self?.delegate?.updateSettingsTabBadge(badgeValue)
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
        case .otherPressed:
            coordinator.navigate(to: .other)
        case .vaultPressed:
            coordinator.navigate(to: .vault)
        }
    }
}
