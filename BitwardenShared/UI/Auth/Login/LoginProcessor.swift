import AuthenticationServices
import BitwardenResources
import BitwardenSdk
import Foundation

// MARK: - CaptchaFlowDelegate

/// An object that is signaled when specific circumstances in the captcha flow have been encountered.
///
@MainActor
protocol CaptchaFlowDelegate: AnyObject {
    /// Called when the captcha flow has been completed successfully.
    ///
    /// - Parameter token: The token that was returned by hCaptcha.
    ///
    func captchaCompleted(token: String)

    /// Called when the captcha flow encounters an error.
    ///
    /// - Parameter error: The error that was encountered.
    ///
    func captchaErrored(error: Error)
}

// MARK: - LoginProcessor

/// The processor used to manage state and handle actions for the login screen.
///
class LoginProcessor: StateProcessor<LoginState, LoginAction, LoginEffect> {
    // MARK: Types

    typealias Services = HasAppIdService
        & HasAuthRepository
        & HasAuthService
        & HasCaptchaService
        & HasConfigService
        & HasDeviceAPIService
        & HasErrorReporter
        & HasPolicyService

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// A flag indicating if this is the first time that the view has appeared.
    ///
    /// This flag keeps us from making the known device call multiple times as the user navigates away from,
    /// and back to the same instance of `LoginView`.
    private var isFirstAppeared = true

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `LoginProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: LoginState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: LoginEffect) async {
        switch effect {
        case .appeared:
            await refreshKnownDevice()
        case .loginWithMasterPasswordPressed:
            await loginWithMasterPassword()
        }
    }

    override func receive(_ action: LoginAction) {
        switch action {
        case .enterpriseSingleSignOnPressed:
            coordinator.navigate(to: .enterpriseSingleSignOn(email: state.username))
        case .getMasterPasswordHintPressed:
            coordinator.navigate(to: .masterPasswordHint(username: state.username))
        case .loginWithDevicePressed:
            coordinator.navigate(to: .loginWithDevice(
                email: state.username,
                authRequestType: AuthRequestType.authenticateAndUnlock,
                isAuthenticated: false
            ))
        case let .masterPasswordChanged(newValue):
            state.masterPassword = newValue
        case .notYouPressed:
            coordinator.navigate(to: .landing)
        case .revealMasterPasswordFieldPressed:
            state.isMasterPasswordRevealed.toggle()
        }
    }

    // MARK: Private Methods

    /// Generates the items needed and authenticates with the captcha flow.
    ///
    /// - Parameter siteKey: The site key that was returned with a captcha error. The token used to authenticate
    ///   with hCaptcha.
    ///
    private func launchCaptchaFlow(with siteKey: String) async {
        do {
            let url = try services.captchaService.generateCaptchaUrl(with: siteKey)
            coordinator.navigate(
                to: .captcha(
                    url: url,
                    callbackUrlScheme: services.captchaService.callbackUrlScheme
                ),
                context: self
            )
        } catch {
            await handleErrorResponse(error)
        }
    }

    /// Attempts to log the user in with the email address and password values found in `state`.
    ///
    /// - Parameter captchaToken: An optional captcha token value to add to the token request.
    ///
    private func loginWithMasterPassword(captchaToken: String? = nil) async {
        // Hide the loading overlay when exiting this method, in case it hasn't been hidden yet.
        defer { coordinator.hideLoadingOverlay() }

        do {
            try EmptyInputValidator(fieldName: Localizations.masterPassword)
                .validate(input: state.masterPassword)
            coordinator.showLoadingOverlay(title: Localizations.loggingIn)

            // Login.
            try await services.authService.loginWithMasterPassword(
                state.masterPassword,
                username: state.username,
                captchaToken: captchaToken,
                isNewAccount: state.isNewAccount
            )

            // Unlock the vault.
            try await services.authRepository.unlockVaultWithPassword(password: state.masterPassword)
            // Complete the login flow.
            coordinator.hideLoadingOverlay()
            await coordinator.handleEvent(.didCompleteAuth)
        } catch let error as InputValidationError {
            coordinator.showAlert(.inputValidationAlert(error: error))
        } catch let error as IdentityTokenRequestError {
            switch error {
            case let .captchaRequired(hCaptchaSiteCode):
                await launchCaptchaFlow(with: hCaptchaSiteCode)
            case let .twoFactorRequired(authMethodsData, _, _, _):
                coordinator.navigate(
                    to: .twoFactor(state.username, .password(state.masterPassword), authMethodsData, nil)
                )
            case .twoFactorProvidersNotConfigured:
                await handleErrorResponse(error)
            case .newDeviceNotVerified:
                coordinator.navigate(
                    to: .twoFactor(
                        state.username,
                        .password(state.masterPassword),
                        AuthMethodsData(email: Email(email: state.username)),
                        nil,
                        true
                    )
                )
            case .encryptionKeyMigrationRequired:
                coordinator.showAlert(.encryptionKeyMigrationRequiredAlert(environmentUrl: state.serverURLString))
            }
        } catch {
            await handleErrorResponse(error)
        }
    }

    /// Refreshes the value for known device from the API, and then updates the state to show or hide the
    /// "Login with known device" button based on that value.
    ///
    private func refreshKnownDevice() async {
        guard isFirstAppeared else { return }
        coordinator.showLoadingOverlay(title: Localizations.loading)
        defer {
            isFirstAppeared = false
            coordinator.hideLoadingOverlay()
        }

        do {
            let deviceIdentifier = await services.appIdService.getOrCreateAppId()
            let isKnownDevice = try await services.deviceAPIService.knownDevice(
                email: state.username,
                deviceIdentifier: deviceIdentifier
            )
            state.isLoginWithDeviceVisible = isKnownDevice
        } catch {
            await handleErrorResponse(error)
        }
    }

    /// Handles network error responses.
    ///
    /// Determines whether the Bitwarden server is official or unofficial and passes this information
    /// along with the error to the coordinator to display an appropriate alert on the main thread.
    /// The error is also logged using the error reporter.
    ///
    /// - Parameter error: The error received from the network request.
    ///
    private func handleErrorResponse(_ error: Error) async {
        services.errorReporter.log(error: error)
        let serverConfig = await services.configService.getConfig(isPreAuth: true)
        let isOfficialBitwardenServer = serverConfig?.isOfficialBitwardenServer() ?? true
        coordinator.showAlert(
            .networkResponseError(
                error,
                isOfficialBitwardenServer: isOfficialBitwardenServer
            )
        )
    }
}

// MARK: CaptchaFlowDelegate

extension LoginProcessor: CaptchaFlowDelegate {
    func captchaCompleted(token: String) {
        Task {
            await loginWithMasterPassword(captchaToken: token)
        }
    }

    func captchaErrored(error: Error) {
        guard (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue else { return }

        // Show the alert after a delay to ensure it doesn't try to display over the
        // closing captcha view.
        DispatchQueue.main.asyncAfter(deadline: UI.after(0.6)) {
            Task {
                await self.handleErrorResponse(error)
            }
        }
    }
}
