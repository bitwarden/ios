import BitwardenKit
import BitwardenResources
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

    /// Task that observes `configPublisher()` for live `disableUserRegistration` updates.
    private var configSubscriptionTask: Task<Void, Never>?

    /// Helper class with region specific functions
    private lazy var regionHelper = RegionHelper(
        coordinator: coordinator,
        delegate: self,
        stateService: services.stateService,
    )

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
        state: LandingState,
    ) {
        self.coordinator = coordinator
        self.services = services

        var state = state
        // If the email is already set (for a soft logged out account), don't replace it with the
        // user's remembered email.
        if state.email.isEmpty {
            let rememberedEmail = services.appSettingsStore.rememberedEmail
            state.email = rememberedEmail ?? ""
            state.isRememberMeOn = rememberedEmail != nil
        }
        super.init(state: state)

        // Extract locals so `self` is never read through inside the Task body.
        // A pre-loop `guard let self` would pin self strongly for the loop's lifetime,
        // preventing deinit (and therefore cancellation) until the publisher completes.
        let configService = services.configService
        let stateService = services.stateService
        configSubscriptionTask = Task { [weak self] in
            for await metaConfig in await configService.configPublisher() {
                guard let self else { return }
                guard metaConfig?.isPreAuth == true,
                      await metaConfig?.serverConfig?.isCurrentConfig(
                          for: stateService.getPreAuthEnvironmentURLs(),
                      ) == true else { continue }
                self.state.isCreateAccountButtonHidden = metaConfig?.serverConfig?
                    .settings?.disableUserRegistration == true
            }
        }
    }

    deinit {
        configSubscriptionTask?.cancel()
    }

    // MARK: Methods

    override func perform(_ effect: LandingEffect) async {
        switch effect {
        case .appeared:
            state.isCreateAccountButtonHidden = await currentPreAuthServerConfig()?
                .settings?.disableUserRegistration == true
            await regionHelper.loadRegion()
            await refreshProfileState()
        case .continuePressed:
            updateRememberedEmail()
            await validateEmailAndContinue()
        case let .profileSwitcher(profileEffect):
            await handleProfileSwitcherEffect(profileEffect)
        case .regionPressed:
            var excludedRegions: [RegionType] = [.gov]
            if await currentPreAuthServerConfig() != nil,
               await services.configService.getFeatureFlag(.fedrampGovRegion, isPreAuth: true) {
                excludedRegions = []
            }
            await regionHelper.presentRegionSelectorAlert(
                title: Localizations.loggingInOn,
                currentRegion: state.region,
                excludingRegions: excludedRegions,
            )
        }
    }

    override func receive(_ action: LandingAction) {
        switch action {
        case .createAccountPressed:
            coordinator.navigate(to: .startRegistration, context: self)
        case let .emailChanged(newValue):
            state.email = newValue
        case let .profileSwitcher(profileAction):
            handleProfileSwitcherAction(profileAction)
        case let .rememberMeChanged(newValue):
            state.isRememberMeOn = newValue
            if !newValue {
                updateRememberedEmail()
            }
        case .showPreLoginSettings:
            coordinator.navigate(to: .preLoginSettings)
        case let .toastShown(toast):
            state.toast = toast
        }
    }

    // MARK: Private Methods

    /// Returns the cached pre-auth server config when its vault host matches the current pre-auth
    /// environment URLs, or `nil` when no config is available or the config belongs to a different region.
    ///
    private func currentPreAuthServerConfig() async -> ServerConfig? {
        let serverConfig = await services.configService.getConfig(forceRefresh: false, isPreAuth: true)
        let preAuthURLs = await services.stateService.getPreAuthEnvironmentURLs()
        guard serverConfig?.isCurrentConfig(for: preAuthURLs) == true else { return nil }
        return serverConfig
    }

    /// Refreshes the configuration by forcing a refresh from the config service
    /// and loads the latest feature flags.
    ///
    private func refreshConfig() async {
        await services.configService.getConfig(
            forceRefresh: true,
            isPreAuth: true,
        )
    }

    /// Validate the currently entered email address and navigate to the login screen.
    ///
    private func validateEmailAndContinue() async {
        let email = state.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.isValidEmail(useStrictValidation: false) else {
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

    func dismissProfileSwitcher() {
        coordinator.navigate(to: .dismiss)
    }

    func handleAuthEvent(_ authEvent: AuthEvent) async {
        await coordinator.handleEvent(authEvent)
    }

    func showAddAccount() {
        // No-Op for the landing processor.
    }

    func showAlert(_ alert: BitwardenKit.Alert) {
        coordinator.showAlert(alert)
    }

    func showProfileSwitcher() {
        coordinator.navigate(to: .viewProfileSwitcher, context: self)
    }
}

// MARK: - SelfHostedProcessorDelegate

extension LandingProcessor: SelfHostedProcessorDelegate {
    func didSaveEnvironment(urls: EnvironmentURLData) async {
        await setRegion(.selfHosted, urls)
        state.toast = Toast(title: Localizations.environmentSaved)
        await regionHelper.loadRegion()
    }
}

// MARK: - StartRegistrationDelegate

extension LandingProcessor: StartRegistrationDelegate {
    func didChangeRegion() async {
        await regionHelper.loadRegion()
    }
}

// MARK: - RegionDelegate

extension LandingProcessor: RegionDelegate {
    /// Sets the region and the URLs to use.
    ///
    /// - Parameters:
    ///   - region: The region to use.
    ///   - urls: The URLs that the app should use for the region.
    ///
    func setRegion(_ region: RegionType, _ urls: EnvironmentURLData) async {
        guard !urls.isEmpty else { return }
        await services.environmentService.setPreAuthURLs(urls: urls)
        state.region = region

        // - Using `Task` for `refreshConfig` ensures that this call doesn't delay other operations,
        //   such as closing the Self-host settings view or triggering `.appeared` events. These issues
        //   arose because `refreshConfig` was awaited directly, leading to delays when internet speed
        //   was low.
        Task {
            await refreshConfig()
        }
    }
}
