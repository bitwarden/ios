import AuthenticationServices
import BitwardenKit
import BitwardenResources
import BitwardenSdk
import Foundation

// MARK: - LoginProcessor

/// The processor used to manage state and handle actions for the login screen.
///
class LoginProcessor: StateProcessor<LoginState, LoginAction, LoginEffect> {
    // MARK: Types

    typealias Services = HasAppIDService
        & HasAuthRepository
        & HasAuthService
        & HasConfigService
        & HasDeviceAPIService
        & HasDeviceAuthKeyService
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
        state: LoginState,
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: LoginEffect) async {
        switch effect {
        case .appeared:
            await refreshDeviceAuthKeyAvailability()
            await refreshKnownDevice()
        case .loginWithDeviceAuthKeyPressed:
            await loginWithDeviceAuthKey()
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
                isAuthenticated: false,
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

    /// Attempts to log the user in and unlock the vault with the device auth key on this device.
    ///
    private func loginWithDeviceAuthKey() async {
        // Hide the loading overlay when exiting this method, in case it hasn't been hidden yet.
        defer { coordinator.hideLoadingOverlay() }

        do {
            coordinator.showLoadingOverlay(title: Localizations.loggingIn)

            // Login. This asks for biometrics to read the device auth key.
            let unlockData = try await services.authService.loginWithDeviceAuthKey(email: state.username)

            // Unlock the vault with the PRF key from the same device auth key.
            try await services.authRepository.unlockVaultWithDeviceAuthKey(unlockData: unlockData)

            // Complete the login flow.
            coordinator.hideLoadingOverlay()
            await coordinator.handleEvent(.didCompleteAuth)
        } catch let error as IdentityTokenRequestError {
            await handleErrorResponse(error)
        } catch let error as ServerError {
            await handleErrorResponse(error)
        } catch let error as URLError {
            await handleErrorResponse(error)
        } catch {
            guard !error.isDeviceAuthKeyBiometryCancellation else { return }
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.theDeviceAuthKeyCouldNotBeUsedDescriptionLong,
            ))
        }
    }

    /// Updates the state to show or hide the "Log in with device auth key" button, based on
    /// whether a device auth key for the user exists on this device.
    ///
    private func refreshDeviceAuthKeyAvailability() async {
        guard await services.configService.getFeatureFlag(.deviceAuthKey, isPreAuth: true) else {
            state.isLoginWithDeviceAuthKeyVisible = false
            return
        }
        state.isLoginWithDeviceAuthKeyVisible = await services.deviceAuthKeyService
            .hasDeviceAuthKey(email: state.username)
    }

    /// Attempts to log the user in with the email address and password values found in `state`.
    ///
    ///
    private func loginWithMasterPassword() async {
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
                isNewAccount: state.isNewAccount,
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
            case let .twoFactorRequired(authMethodsData, _, _):
                coordinator.navigate(
                    to: .twoFactor(state.username, .password(state.masterPassword), authMethodsData, nil),
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
                        true,
                    ),
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
            let deviceIdentifier = await services.appIDService.getOrCreateAppID()
            let isKnownDevice = try await services.deviceAPIService.knownDevice(
                email: state.username,
                deviceIdentifier: deviceIdentifier,
            )
            state.isLoginWithDeviceVisible = isKnownDevice
        } catch {
            services.errorReporter.log(error: error)
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
                isOfficialBitwardenServer: isOfficialBitwardenServer,
            ),
        )
    }
}
