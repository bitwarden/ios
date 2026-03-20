import BitwardenKit
import Foundation

// MARK: - PasswordAutoFillProcessor

/// The processor used to manage state and handle actions for the password auto-fill screen.
///
final class PasswordAutoFillProcessor: StateProcessor<
    PasswordAutoFillState,
    PasswordAutoFillAction,
    PasswordAutoFillEffect,
> {
    // MARK: Types

    /// The services used by this processor.
    typealias Services = HasASSettingsMediator
        & HasAutofillCredentialService
        & HasConfigService
        & HasErrorReporter
        & HasNotificationCenterService
        & HasStateService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<PasswordAutofillRoute, PasswordAutofillEvent>?

    /// The delegate to notify of autofill completion events.
    private weak var delegate: (any PasswordAutoFillProcessorDelegate)?

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `PasswordAutoFillProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate to notify of autofill completion events.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<PasswordAutofillRoute, PasswordAutofillEvent>,
        delegate: (any PasswordAutoFillProcessorDelegate)? = nil,
        services: Services,
        state: PasswordAutoFillState,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: PasswordAutoFillEffect) async {
        switch effect {
        case .checkAutofillOnForeground:
            await monitorAutofillCompletionDuringOnboarding()
        case .continueTapped:
            await attemptToTurnOnCredentialProvider()
        case .turnAutoFillOnLaterButtonTapped:
            coordinator?.showAlert(
                .setUpAutoFillLater { [weak self] in
                    await self?.turnOnLaterFlow()
                },
            )
        }
    }

    override func receive(_ action: PasswordAutoFillAction) {
        switch action {
        case .clearURL:
            state.url = nil
        }
    }

    // MARK: Private Functions

    /// Attempts to turn on credential provider for autofill or navigate to the OS specific settings.
    private func attemptToTurnOnCredentialProvider() async {
        if #available(iOS 18, *) {
            do {
                let isOn = try await services.asSettingsMediator.requestToTurnOnCredentialProviderExtension()
                guard isOn else {
                    do {
                        try await services.stateService.setAccountSetupAutofill(.setUpLater)
                    } catch {
                        services.errorReporter.log(error: error)
                    }
                    await navigateOnCompletion()
                    return
                }
            } catch ASSettingsMediatorError.cantRequest {
                try? await services.asSettingsMediator.openVerificationCodeAppSettings()
            } catch {
                services.errorReporter.log(error: error)
            }

            await checkAutofillCompletion()
        } else if #available(iOS 17, *) {
            try? await services.asSettingsMediator.openVerificationCodeAppSettings()
        } else {
            state.url = ExternalLinksConstants.passwordOptions
        }
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
            delegate?.didEnableAutofill()
        } catch {
            services.errorReporter.log(error: error)
        }

        await navigateOnCompletion()
    }

    /// Navigates on completion of trying to turn autofill ON appropriately depending on the mode.
    private func navigateOnCompletion() async {
        switch state.mode {
        case .onboarding:
            await coordinator?.handleEvent(.didCompleteAuth)
        case .settings:
            coordinator?.navigate(to: .dismiss)
        }
    }
}
