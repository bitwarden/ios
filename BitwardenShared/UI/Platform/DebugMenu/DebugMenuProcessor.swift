import Foundation

// MARK: - DebugMenuProcessor

/// The processor used to manage state and handle actions for the `DebugMenuView`.
///
final class DebugMenuProcessor: StateProcessor<DebugMenuState, DebugMenuAction, DebugMenuEffect> {
    // MARK: Types

    typealias Services = HasAppSettingsStore
        & HasConfigService

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<DebugMenuRoute, Void>

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a `DebugMenuProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by the processor.
    ///   - state: The state of the debug menu.
    ///
    init(
        coordinator: AnyCoordinator<DebugMenuRoute, Void>,
        services: Services,
        state: DebugMenuState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: DebugMenuAction) {
        switch action {
        case .dismissTapped:
            coordinator.navigate(to: .dismiss)
        }
    }

    override func perform(_ effect: DebugMenuEffect) async {
        switch effect {
        case .viewAppeared:
            await fetchFlags()
        case .refreshFeatureFlags:
            await refreshFlags()
        case let .toggleFeatureFlag(flag, newValue):
            services.appSettingsStore.setFeatureFlag(
                name: flag,
                value: newValue
            )
            await fetchFlags()
        }
    }

    // MARK: Private Functions

    /// Asynchronously fetches and updates feature flags for the debug menu.
    /// If we are in a DEBUG build, we will try to use the value stored in User Defaults,
    /// otherwise use the remote state or default to false.
    private func fetchFlags() async {
        let remoteFeatureFlags = await services.configService.getRemoteFeatureFlags()

        state.featureFlags = FeatureFlag.allCases.map { feature in
            let userDefaultValue = services.appSettingsStore.featureFlag(name: feature.rawValue)
            let remoteFlagValue = remoteFeatureFlags[feature]?.boolValue ?? false

            return DebugMenuFeatureFlag(
                feature: feature,
                isEnabled: userDefaultValue ?? remoteFlagValue
            )
        }
    }

    /// Refreshes the feature flags by resetting their local values and fetching the latest configurations.
    private func refreshFlags() async {
        for feature in FeatureFlag.allCases {
            services.appSettingsStore.setFeatureFlag(name: feature.rawValue, value: nil)
        }
        await fetchFlags()
    }
}
