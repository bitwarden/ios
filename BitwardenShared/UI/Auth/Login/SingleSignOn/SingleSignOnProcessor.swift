import AuthenticationServices
import BitwardenResources
import Foundation

// MARK: - SingleSignOnFlowDelegate

/// An object that is signaled when specific circumstances in the single sign on flow have been encountered.
///
@MainActor
protocol SingleSignOnFlowDelegate: AnyObject {
    /// Called when the single sign on flow has been completed successfully.
    ///
    /// - Parameter code: The code that was returned by the single sign on web auth process.
    ///
    func singleSignOnCompleted(code: String)

    /// Called when the single sign on flow encounters an error.
    ///
    /// - Parameter error: The error that was encountered.
    ///
    func singleSignOnErrored(error: Error)
}

// MARK: - SingleSignOnProcessor

/// The processor used to manage state and handle actions for the `SingleSignOnView`.
///
final class SingleSignOnProcessor: StateProcessor<SingleSignOnState, SingleSignOnAction, SingleSignOnEffect> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasAuthService
        & HasConfigService
        & HasErrorReporter
        & HasOrganizationAPIService
        & HasStateService

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `SingleSignOnProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: SingleSignOnState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SingleSignOnEffect) async {
        switch effect {
        case .loadSingleSignOnDetails:
            await loadSingleSignOnDetails()
        case .loginTapped:
            await handleLoginTapped()
        }
    }

    override func receive(_ action: SingleSignOnAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .identifierTextChanged(newValue):
            state.identifierText = newValue
        }
    }

    // MARK: Private Methods

    /// Generically handle an error on the view.
    private func handleError(_ error: Error, _ tryAgain: (() async -> Void)? = nil) async {
        coordinator.hideLoadingOverlay()
        switch error {
        case ASWebAuthenticationSessionError.canceledLogin:
            break
        case let IdentityTokenRequestError.twoFactorRequired(authMethodsData, _, _, _):
            rememberOrgIdentifierAndNavigate(to: .twoFactor(state.email, nil, authMethodsData, state.identifierText))
        case AuthError.requireSetPassword:
            rememberOrgIdentifierAndNavigate(to: .setMasterPassword(organizationIdentifier: state.identifierText))
        case AuthError.requireUpdatePassword:
            rememberOrgIdentifierAndNavigate(to: .updateMasterPassword)
        case AuthError.requireDecryptionOptions:
            rememberOrgIdentifierAndNavigate(to: .showLoginDecryptionOptions(
                organizationIdentifier: state.identifierText
            ))
        default:
            await coordinator.showErrorAlert(error: error, tryAgain: tryAgain)
            services.errorReporter.log(error: error)
        }
    }

    /// Handle attempting to login.
    private func handleLoginTapped() async {
        do {
            try EmptyInputValidator(fieldName: Localizations.orgIdentifier)
                .validate(input: state.identifierText)
            coordinator.showLoadingOverlay(title: Localizations.loggingIn)

            // Generate the URL and initiate a web auth view with it.
            let result = try await services.authService.generateSingleSignOnUrl(from: state.identifierText)
            coordinator.navigate(
                to: .singleSignOn(
                    callbackUrlScheme: services.authService.callbackUrlScheme,
                    state: result.state,
                    url: result.url
                ),
                context: self
            )
        } catch let error as InputValidationError {
            coordinator.hideLoadingOverlay()
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
        } catch {
            await handleError(error) { await self.handleLoginTapped() }
        }
    }

    /// Load the single sign on details to ensure the user is able to complete the single sign on process
    /// and attempt to start the WebAuth session if applicable.
    private func loadSingleSignOnDetails() async {
        coordinator.showLoadingOverlay(title: Localizations.loading)
        defer {
            coordinator.hideLoadingOverlay()
        }

        // Get the single sign on details for the user.
        do {
            guard let organizationIdentifier = try await services.authRepository
                .getSingleSignOnOrganizationIdentifier(email: state.email)
            else {
                // Default back to the last used org identifier if the API doesn't return one.
                state.identifierText = services.stateService.rememberedOrgIdentifier ?? ""
                return
            }

            state.identifierText = organizationIdentifier
            coordinator.hideLoadingOverlay()
            await handleLoginTapped()
        } catch {
            // Default back to the last used org identifier if the API doesn't return one.
            state.identifierText = services.stateService.rememberedOrgIdentifier ?? ""
            services.errorReporter.log(error: error)
        }
    }

    /// Remembers the org identifier for future logins and navigates to the specified route.
    ///
    /// - Parameter route: The route to navigate to after saving the org identifier.
    ///
    private func rememberOrgIdentifierAndNavigate(to route: AuthRoute) {
        services.stateService.rememberedOrgIdentifier = state.identifierText
        coordinator.navigate(to: route)
    }

    /// Migrates a new user to KeyConnector and unlocks the vault with the KeyConnector
    ///
    /// - Parameter keyConnectorUrl: The organization's KeyConnector domain
    ///
    private func migrateUserKeyConnector(keyConnectorUrl: URL) async {
        do {
            try await services.authRepository.convertNewUserToKeyConnector(
                keyConnectorURL: keyConnectorUrl,
                orgIdentifier: state.identifierText
            )

            try await services.authRepository.unlockVaultWithKeyConnectorKey(
                keyConnectorURL: keyConnectorUrl,
                orgIdentifier: state.identifierText
            )

            await coordinator.handleEvent(.didCompleteAuth)
            coordinator.navigate(to: .dismiss)
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }
}

// MARK: - SingleSignOnFlowDelegate

extension SingleSignOnProcessor: SingleSignOnFlowDelegate {
    func singleSignOnCompleted(code: String) {
        // Complete the login process using the single sign on information.
        Task {
            do {
                // Use the code to authenticate the user with Bitwarden.
                let unlockMethod = try await self.services.authService.loginWithSingleSignOn(
                    code: code,
                    email: state.email
                )

                // Remember the organization identifier after successfully logging on.
                services.stateService.rememberedOrgIdentifier = state.identifierText

                // Dismiss the loading overlay.
                coordinator.hideLoadingOverlay()

                // Show the appropriate view and dismiss this sheet.
                switch unlockMethod {
                case .deviceKey:
                    // Attempt to unlock the vault with tde.
                    try await services.authRepository.unlockVaultWithDeviceKey()
                    await coordinator.handleEvent(.didCompleteAuth)
                    coordinator.navigate(to: .dismiss)
                case let .masterPassword(account):
                    coordinator.navigate(
                        to: .vaultUnlock(
                            account,
                            animated: false,
                            attemptAutomaticBiometricUnlock: true,
                            didSwitchAccountAutomatically: false
                        )
                    )
                    coordinator.navigate(to: .dismiss)
                case let .keyConnector(keyConnectorUrl):
                    do {
                        try await services.authRepository.unlockVaultWithKeyConnectorKey(
                            keyConnectorURL: keyConnectorUrl,
                            orgIdentifier: state.identifierText
                        )
                        await coordinator.handleEvent(.didCompleteAuth)
                        coordinator.navigate(to: .dismiss)
                    } catch StateServiceError.noEncryptedPrivateKey {
                        // The delay is necessary in order to ensure the alert displays over the WebAuth view.
                        Task { @MainActor in
                            try await Task.sleep(forSeconds: UI.duration(0.5))
                            coordinator.showAlert(Alert.keyConnectorConfirmation(keyConnectorUrl: keyConnectorUrl) {
                                await self.migrateUserKeyConnector(keyConnectorUrl: keyConnectorUrl)
                            })
                        }
                    }
                }
            } catch {
                // The delay is necessary in order to ensure the alert displays over the WebAuth view.
                Task { @MainActor in
                    try await Task.sleep(forSeconds: UI.duration(0.5))
                    await self.handleError(error)
                }
            }
        }
    }

    func singleSignOnErrored(error: Error) {
        // The delay is necessary in order to ensure the alert displays over the WebAuth view.
        Task { @MainActor in
            try await Task.sleep(forSeconds: UI.duration(0.5))
            await self.handleError(error)
        }
    }
}
