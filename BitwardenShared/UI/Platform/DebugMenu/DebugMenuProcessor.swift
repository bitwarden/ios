import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - DebugMenuProcessor

/// The processor used to manage state and handle actions for the `DebugMenuView`.
///
final class DebugMenuProcessor: StateProcessor<DebugMenuState, DebugMenuAction, DebugMenuEffect> {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter

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
        case .generateCrash:
            preconditionFailure("Generated crash from debug view.")
        case .generateErrorReport:
            services.errorReporter.log(error: BitwardenSdk.BitwardenError.E(
                message: "Generated error report from debug view.")
            )
            services.errorReporter.log(error: KeychainServiceError.osStatusError(1))
        }
    }

    override func perform(_ effect: DebugMenuEffect) async {
        switch effect {
        case .viewAppeared:
            await fetchFlags()
        case .refreshFeatureFlags:
            await refreshFlags()
        case let .toggleFeatureFlag(flag, newValue):
            await services.configService.toggleDebugFeatureFlag(
                name: flag,
                newValue: newValue
            )
            state.featureFlags = await services.configService.getDebugFeatureFlags(FeatureFlag.allCases)
        }
    }

    // MARK: Private Functions

    /// Fetch the current debug feature flags.
    private func fetchFlags() async {
        state.featureFlags = await services.configService.getDebugFeatureFlags(FeatureFlag.allCases)
    }

    /// Refreshes the feature flags by resetting their local values and fetching the latest configurations.
    private func refreshFlags() async {
        state.featureFlags = await services.configService.refreshDebugFeatureFlags(FeatureFlag.allCases)
    }
}
