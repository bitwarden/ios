import Foundation

// MARK: - PasswordAutoFillProcessor

/// The processor used to manage state and handle actions for the password auto-fill screen.
///
final class PasswordAutoFillProcessor: StateProcessor<PasswordAutoFillState, Void, PasswordAutoFillEffect> {
    // MARK: Types

    /// The services used by this processor.
    typealias Services = HasAutofillCredentialService
        & HasConfigService
        & HasErrorReporter
        & HasNotificationCenterService
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
        case .checkAutofillOnForeground:
            await monitorAutofillCompletionDuringOnboarding()
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
            .nativeCreateAccountFlow
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

    /// Monitors the autofill completion process during onboarding mode.
    /// When the app enters the foreground and autofill credentials are enabled,
    /// it completes the account setup process and triggers the appropriate event.
    ///
    private func monitorAutofillCompletionDuringOnboarding() async {
        guard state.mode == .onboarding else { return }

        for await _ in services.notificationCenterService.willEnterForegroundPublisher() {
            await checkAutofillCompletion()
        }
    }

    /// Checks if autofill credentials are enabled, and if so,
    /// completes the account setup process by updating the state and triggering the necessary event.
    /// If an error occurs while updating the state, it logs the error using the error reporter.
    ///
    private func checkAutofillCompletion() async {
        guard await services.autofillCredentialService.isAutofillCredentialsEnabled() else { return }

        do {
            try await services.stateService.setAccountSetupAutofill(.complete)
        } catch {
            services.errorReporter.log(error: error)
        }

        await coordinator?.handleEvent(.didCompleteAuth)
    }
}
