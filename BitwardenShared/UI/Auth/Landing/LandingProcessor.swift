import Combine
import SwiftUI

// MARK: - LandingProcessor

/// The processor used to manage state and handle actions for the landing screen.
///
class LandingProcessor: StateProcessor<LandingState, LandingAction, LandingEffect> {
    // MARK: Types

    typealias Services = HasAppSettingsStore
        & HasAuthRepository
        & HasConfigService
        & HasEnvironmentService
        & HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `LandingProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: LandingState
    ) {
        self.coordinator = coordinator
        self.services = services

        let rememberedEmail = services.appSettingsStore.rememberedEmail
        var state = state
        state.email = rememberedEmail ?? ""
        state.isRememberMeOn = rememberedEmail != nil

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: LandingEffect) async {
        switch effect {
        case .appeared:
            await loadFeatureFlag()
            await loadRegion()
            await refreshProfileState()
        case .continuePressed:
            updateRememberedEmail()
            await validateEmailAndContinue()
        case let .profileSwitcher(profileEffect):
            await handleProfileSwitcherEffect(profileEffect)
        }
    }

    override func receive(_ action: LandingAction) {
        switch action {
        case .createAccountPressed:
            if state.emailVerificationFeatureFlag {
                coordinator.navigate(to: .startRegistration, context: self)
            } else {
                coordinator.navigate(to: .createAccount)
            }
        case let .emailChanged(newValue):
            state.email = newValue
        case let .profileSwitcher(profileAction):
            handleProfileSwitcherAction(profileAction)
        case .regionPressed:
            presentRegionSelectionAlert()
        case let .rememberMeChanged(newValue):
            state.isRememberMeOn = newValue
            if !newValue {
                updateRememberedEmail()
            }
        case let .toastShown(toast):
            state.toast = toast
        }
    }

    // MARK: Private Methods

    /// Sets the feature flag value to be used.
    ///
    private func loadFeatureFlag() async {
        state.emailVerificationFeatureFlag = await services.configService.getFeatureFlag(
            FeatureFlag.emailVerification,
            defaultValue: true,
            forceRefresh: true
        )
    }

    /// Sets the region to the last used region.
    ///
    private func loadRegion() async {
        guard let urls = await services.stateService.getPreAuthEnvironmentUrls() else {
            await setRegion(.unitedStates, urls: .defaultUS)
            return
        }

        if urls.base == EnvironmentUrlData.defaultUS.base {
            await setRegion(.unitedStates, urls: urls)
        } else if urls.base == EnvironmentUrlData.defaultEU.base {
            await setRegion(.europe, urls: urls)
        } else {
            await setRegion(.selfHosted, urls: urls)
        }
    }

    /// Validate the currently entered email address and navigate to the login screen.
    ///
    private func validateEmailAndContinue() async {
        let email = state.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.isValidEmail else {
            coordinator.showAlert(.invalidEmail)
            return
        }

        if let userId = await services.authRepository.existingAccountUserId(email: email) {
            coordinator.showAlert(.switchToExistingAccount {
                await self.coordinator.handleEvent(.action(.switchAccount(isAutomatic: false, userId: userId)))
            })
            return
        }

        coordinator.navigate(to: .login(username: email))
    }

    /// Builds an alert for region selection and navigates to the alert.
    ///
    private func presentRegionSelectionAlert() {
        let actions = RegionType.allCases.map { region in
            AlertAction(title: region.baseUrlDescription, style: .default) { [weak self] _ in
                if let urls = region.defaultURLs {
                    await self?.setRegion(region, urls: urls)
                } else {
                    self?.coordinator.navigate(
                        to: .selfHosted(currentRegion: self?.state.region ?? .unitedStates),
                        context: self
                    )
                }
            }
        }
        let cancelAction = AlertAction(title: Localizations.cancel, style: .cancel)
        let alert = Alert(
            title: Localizations.loggingInOn,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: actions + [cancelAction]
        )
        coordinator.showAlert(alert)
    }

    /// Sets the region and the URLs to use.
    ///
    /// - Parameters:
    ///   - region: The region to use.
    ///   - urls: The URLs that the app should use for the region.
    ///
    private func setRegion(_ region: RegionType, urls: EnvironmentUrlData) async {
        guard !urls.isEmpty else { return }
        await services.environmentService.setPreAuthURLs(urls: urls)
        state.region = region
    }

    /// Updates the value of `rememberedEmail` in the app settings store with the `email` value in `state`.
    ///
    private func updateRememberedEmail() {
        if state.isRememberMeOn {
            services.appSettingsStore.rememberedEmail = state.email
        } else {
            services.appSettingsStore.rememberedEmail = nil
        }
    }
}

// MARK: - ProfileSwitcherHandler

extension LandingProcessor: ProfileSwitcherHandler {
    var allowLockAndLogout: Bool {
        true
    }

    var profileServices: ProfileServices {
        services
    }

    var profileSwitcherState: ProfileSwitcherState {
        get {
            state.profileSwitcherState
        }
        set {
            state.profileSwitcherState = newValue
        }
    }

    var shouldHideAddAccount: Bool {
        true
    }

    var showPlaceholderToolbarIcon: Bool {
        true
    }

    var toast: Toast? {
        get {
            state.toast
        }
        set {
            state.toast = newValue
        }
    }

    func handleAuthEvent(_ authEvent: AuthEvent) async {
        await coordinator.handleEvent(authEvent)
    }

    func showAddAccount() {
        // No-Op for the landing processor.
    }

    func showAlert(_ alert: Alert) {
        coordinator.showAlert(alert)
    }
}

// MARK: - SelfHostedProcessorDelegate

extension LandingProcessor: SelfHostedProcessorDelegate {
    func didSaveEnvironment(urls: EnvironmentUrlData) async {
        await setRegion(.selfHosted, urls: urls)
        state.toast = Toast(text: Localizations.environmentSaved)
        await loadRegion()
    }
}

// MARK: - StartRegistrationDelegate

extension LandingProcessor: StartRegistrationDelegate {
    func didChangeRegion() async {
        await loadRegion()
    }
}
