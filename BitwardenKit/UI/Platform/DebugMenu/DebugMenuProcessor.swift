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

    // MARK: Computed Properties

    /// The current feature flags. This requires `FeatureFlag` to have been extended in the executable's
    /// namespace to conform to `CaseIterable`.
    private var currentFeatureFlags: [FeatureFlag] {
        guard let featureFlagType = FeatureFlag.self as? any CaseIterable.Type,
              let flags = featureFlagType.allCases as? [FeatureFlag] else {
            return []
        }
        return flags
    }

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
        state: DebugMenuState,
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
            services.errorReporter.log(
                error: FlightRecorderError.fileSizeError(
                    NSError(
                        domain: "Generated Error",
                        code: 0,
                        userInfo: [
                            "AdditionalMessage": "Generated error report from debug view.",
                        ],
                    ),
                ),
            )
        case .generateSdkErrorReport:
            services.errorReporter.log(error: BitwardenSdk.BitwardenError.Api(ApiError.ResponseContent(
                message: "Generated SDK error report from debug view.",
            )))
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
                newValue: newValue,
            )
            state.featureFlags = await services.configService.getDebugFeatureFlags(currentFeatureFlags)
        }
    }

    // MARK: Private Functions

    /// Fetch the current debug feature flags.
    private func fetchFlags() async {
        state.featureFlags = await services.configService.getDebugFeatureFlags(currentFeatureFlags)
    }

    /// Refreshes the feature flags by resetting their local values and fetching the latest configurations.
    private func refreshFlags() async {
        state.featureFlags = await services.configService.refreshDebugFeatureFlags(currentFeatureFlags)
    }
}
