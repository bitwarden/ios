import Foundation

// MARK: - PasswordAutoFillProcessor

/// The processor used to manage state and handle actions for the password auto-fill screen.
///
final class PasswordAutoFillProcessor: StateProcessor<PasswordAutoFillState, Void, PasswordAutoFillEffect> {
    // MARK: Types

    /// The services used by this processor.
    typealias Services = HasConfigService
        & HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>?

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `PasswordAutoFillProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>? = nil,
        services: Services,
        state: PasswordAutoFillState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: PasswordAutoFillEffect) async {
        switch effect {
        case .appeared:
            await loadFeatureFlag()
        case .turnAutoFillOnLaterButtonTapped:
            coordinator?.showAlert(
                .setUpAutoFillLater { [weak self] in
                    await self?.turnOnLaterFlow()
                }
            )
        }
    }

    // MARK: Private Functions

    /// Sets the feature flag value to be used.
    ///
    private func loadFeatureFlag() async {
        state.nativeCreateAccountFeatureFlag = await services.configService.getFeatureFlag(
            .nativeCreateAccountFlow,
            isPreAuth: true
        )
    }

    /// Continues the set up unlock flow by navigating to autofill setup.
    ///
    private func turnOnLaterFlow() async {
        do {
            try await services.stateService.setAccountSetupAutofill(.setUpLater)
        } catch {
            services.errorReporter.log(error: error)
        }
        await coordinator?.handleEvent(.didCompleteAuth)
    }
}
