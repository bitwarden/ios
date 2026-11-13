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

    /// Whether onboarding has been completed, used to ensure it's only completed once.
    private var hasCompletedOnboarding = false

    /// Whether the user was sent to the device's Settings app during onboarding and the
    /// processor is waiting for the app to return to the foreground.
    private var isAwaitingReturnFromSettings = false

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
            await monitorAutofillOnForeground()
        case .continueTapped:
            switch state.mode {
            case .onboarding:
                await continueOnboarding()
            case .settings:
                await attemptToTurnOnCredentialProvider()
            }
        case .turnAutoFillOnLaterButtonTapped:
            coordinator?.showAlert(
                .setUpAutoFillLater { [weak self] in
                    await self?.completeOnboarding()
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
    /// This is used in the settings mode.
    ///
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
                try? await services.asSettingsMediator.openCredentialProviderAppSettings()
            } catch {
                services.errorReporter.log(error: error)
            }

            await checkAutofillCompletion()
        } else if #available(iOS 17, *) {
            try? await services.asSettingsMediator.openCredentialProviderAppSettings()
        } else {
            state.url = ExternalLinksConstants.passwordOptions
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

    /// Completes the autofill onboarding step and navigates on completion. This only completes
    /// onboarding once; subsequent calls are ignored.
    ///
    private func completeOnboarding() async {
        guard !hasCompletedOnboarding else { return }
        hasCompletedOnboarding = true
        isAwaitingReturnFromSettings = false

        await updateAccountSetupAutofillProgressIfNeeded()
        await navigateOnCompletion()
    }

    /// Handles the continue button in the onboarding mode. On iOS 18+, this requests to turn on
    /// the credential provider extension and then completes onboarding regardless of the result.
    /// If the request can't be made (e.g. a request was made too recently) or on earlier versions,
    /// this opens the device's Settings app and onboarding is completed when the app returns to
    /// the foreground.
    ///
    private func continueOnboarding() async {
        guard #available(iOS 18, *) else {
            await openSettingsDuringOnboarding()
            return
        }

        do {
            _ = try await services.asSettingsMediator.requestToTurnOnCredentialProviderExtension()
        } catch ASSettingsMediatorError.cantRequest {
            // The system prompt can't be shown right now, so fall back to opening Settings.
            await openSettingsDuringOnboarding()
            return
        } catch {
            services.errorReporter.log(error: error)
        }
        await completeOnboarding()
    }

    /// Handles the app returning to the foreground during onboarding. Onboarding is completed if
    /// the user is returning from the device's Settings app or if autofill is now enabled.
    ///
    private func handleForegroundDuringOnboarding() async {
        if isAwaitingReturnFromSettings {
            await completeOnboarding()
        } else if await services.autofillCredentialService.isAutofillCredentialsEnabled() {
            await completeOnboarding()
        }
    }

    /// Monitors for the app entering the foreground. In onboarding mode, this completes onboarding
    /// if the user is returning from the device's Settings app or autofill is enabled. In settings
    /// mode, this checks whether autofill was enabled and if so, dismisses the view.
    ///
    private func monitorAutofillOnForeground() async {
        for await _ in services.notificationCenterService.willEnterForegroundPublisher() {
            switch state.mode {
            case .onboarding:
                await handleForegroundDuringOnboarding()
            case .settings:
                await checkAutofillCompletion()
            }
        }
    }

    /// Opens the device's Settings app during onboarding so the user can turn on autofill. On
    /// iOS 17+, this opens the AutoFill & Passwords settings; on earlier versions, this opens the
    /// Password Options settings. Onboarding is completed when the app returns to the foreground.
    ///
    private func openSettingsDuringOnboarding() async {
        isAwaitingReturnFromSettings = true
        if #available(iOS 17, *) {
            do {
                try await services.asSettingsMediator.openCredentialProviderAppSettings()
            } catch {
                isAwaitingReturnFromSettings = false
                services.errorReporter.log(error: error)
            }
        } else {
            state.url = ExternalLinksConstants.passwordOptions
        }
    }

    /// Updates the autofill setup progress when the onboarding step is completed, based on whether
    /// autofill is turned on, so the step isn't shown again. This is only needed if account setup
    /// onboarding on sign-in is disabled, since the stored progress then determines which steps are
    /// shown.
    ///
    private func updateAccountSetupAutofillProgressIfNeeded() async {
        guard await !services.configService.getFeatureFlag(.accountSetupOnboardingOnSignIn) else { return }
        let isAutofillEnabled = await services.autofillCredentialService.isAutofillCredentialsEnabled()
        do {
            try await services.stateService.setAccountSetupAutofill(isAutofillEnabled ? .complete : .setUpLater)
        } catch {
            services.errorReporter.log(error: error)
        }
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
