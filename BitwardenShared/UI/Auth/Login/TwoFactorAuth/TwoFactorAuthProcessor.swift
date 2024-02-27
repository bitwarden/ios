import AuthenticationServices
import Foundation

// MARK: - TwoFactorAuthProcessor

/// The processor used to manage state and handle actions for the `TwoFactorAuthView`.
///
final class TwoFactorAuthProcessor: StateProcessor<TwoFactorAuthState, TwoFactorAuthAction, TwoFactorAuthEffect> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasAuthService
        & HasCaptchaService
        & HasEnvironmentService
        & HasErrorReporter
        & HasNFCReaderService

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a `TwoFactorAuthProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: TwoFactorAuthState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)

        setUpState()
    }

    deinit {
        services.nfcReaderService.stopReading()
    }

    // MARK: Methods

    override func perform(_ effect: TwoFactorAuthEffect) async {
        switch effect {
        case .beginDuoAuth:
            authenticateWithDuo()
        case .continueTapped:
            await login()
        case .listenForNFC:
            await listenForNFC()
        case let .receivedDuoToken(duoToken):
            state.verificationCode = duoToken
            await login()
        case .resendEmailTapped:
            await resendEmail()
        }
    }

    override func receive(_ action: TwoFactorAuthAction) {
        switch action {
        case let .authMethodSelected(authMethod):
            handleAuthMethodSelected(authMethod)
        case .clearURL:
            state.url = nil
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .rememberMeToggleChanged(isOn):
            state.isRememberMeOn = isOn
        case let .toastShown(newValue):
            state.toast = newValue
        case let .verificationCodeChanged(newValue):
            state.verificationCode = newValue
            state.continueEnabled = (newValue.count >= 6)
        }
    }

    // MARK: Private Methods

    /// Update the selected auth method or launch the web view for the recovery code.
    private func handleAuthMethodSelected(_ authMethod: TwoFactorAuthMethod) {
        if authMethod == .recoveryCode {
            state.url = ExternalLinksConstants.recoveryCode
        } else {
            state.authMethod = authMethod
        }
    }

    /// Generates the items needed and authenticates with the captcha flow.
    ///
    /// - Parameter siteKey: The site key that was returned with a captcha error. The token used to authenticate
    ///   with hCaptcha.
    ///
    private func launchCaptchaFlow(with siteKey: String) {
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
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Listens for a Yubikey NFC tag.
    private func listenForNFC() async {
        do {
            services.nfcReaderService.startReading()
            for try await result in try await services.nfcReaderService.resultPublisher() {
                guard let result else { continue }
                state.verificationCode = result
                await login()
                break
            }
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.networkResponseError(error))
        }
    }

    /// Attempt to login.
    private func login(captchaToken: String? = nil) async {
        // Hide the loading overlay when exiting this method, in case it hasn't been hidden yet.
        defer { coordinator.hideLoadingOverlay() }

        do {
            try EmptyInputValidator(fieldName: Localizations.verificationCode)
                .validate(input: state.verificationCode)
            coordinator.showLoadingOverlay(title: Localizations.verifying)

            // If the user is manually entering a code, remove any white spaces, just in case.
            var code = state.verificationCode
            if state.authMethod == .authenticatorApp || state.authMethod == .email {
                code = code.replacingOccurrences(of: " ", with: "")
            }

            // Attempt to login.
            let account = try await services.authService.loginWithTwoFactorCode(
                email: state.email,
                code: code,
                method: state.authMethod,
                remember: state.isRememberMeOn,
                captchaToken: captchaToken
            )

            // Try to unlock the vault with the unlock method.
            if let unlockMethod = state.unlockMethod {
                try await unlockVault(unlockMethod: unlockMethod)
                coordinator.hideLoadingOverlay()
                await coordinator.handleEvent(.didCompleteAuth)
            } else {
                // Otherwise, navigate to the unlock vault view.
                coordinator.hideLoadingOverlay()
                coordinator.navigate(
                    to: .vaultUnlock(
                        account,
                        animated: false,
                        attemptAutomaticBiometricUnlock: true,
                        didSwitchAccountAutomatically: false
                    )
                )
                coordinator.navigate(to: .dismiss)
            }
        } catch let error as InputValidationError {
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
        } catch let error as IdentityTokenRequestError {
            if case let .captchaRequired(hCaptchaSiteCode) = error {
                launchCaptchaFlow(with: hCaptchaSiteCode)
            } else {
                coordinator.showAlert(.defaultAlert(
                    title: Localizations.anErrorHasOccurred,
                    message: Localizations.invalidVerificationCode
                ))
            }
        } catch {
            coordinator.showAlert(.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.invalidVerificationCode
            ))
            services.errorReporter.log(error: error)
        }
    }

    /// Resend the verification code email.
    private func resendEmail() async {
        guard state.authMethod == .email else { return }
        do {
            coordinator.showLoadingOverlay(title: Localizations.submitting)

            try await services.authService.resendVerificationCodeEmail()

            coordinator.hideLoadingOverlay()
            state.toast = Toast(text: Localizations.verificationEmailSent)
        } catch {
            coordinator.hideLoadingOverlay()
            coordinator.showAlert(.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.verificationEmailNotSent
            ))
            services.errorReporter.log(error: error)
        }
    }

    /// Set up the initial parameters of the state.
    private func setUpState() {
        // Determine all the available auth methods for the user, adding on the recovery code
        // which is always available.
        var availableMethods = state
            .authMethodsData
            .keys
            .sorted()
            .compactMap(TwoFactorAuthMethod.init)
        availableMethods.append(.recoveryCode)
        state.availableAuthMethods = availableMethods

        // The default two-factor auth provider is the one with the highest priority.
        let preferredMethod = availableMethods.max(by: { $1.priority > $0.priority })
        state.authMethod = preferredMethod ?? .email

        // If email is one of the options, then parse the data to get the email to display.
        if availableMethods.contains(.email),
           let emailData = state.authMethodsData["\(TwoFactorAuthMethod.email.rawValue)"],
           let emailToDisplay = emailData?["Email"] {
            state.displayEmail = emailToDisplay?.stringValue ?? state.email
        }
    }

    /// Attempts to unlock the user's vault with the specified unlock method.
    ///
    /// - Parameter unlockMethod: The method used to unlock the vault.
    ///
    private func unlockVault(unlockMethod: TwoFactorUnlockMethod) async throws {
        switch unlockMethod {
        case let .password(password):
            try await services.authRepository.unlockVaultWithPassword(password: password)
        case let .loginWithDevice(key, masterPasswordHash, privateKey):
            try await services.authRepository.unlockVaultFromLoginWithDevice(
                privateKey: privateKey,
                key: key,
                masterPasswordHash: masterPasswordHash
            )
        }
    }
}

// MARK: CaptchaFlowDelegate

extension TwoFactorAuthProcessor: CaptchaFlowDelegate {
    func captchaCompleted(token: String) {
        Task {
            await login(captchaToken: token)
        }
    }

    func captchaErrored(error: Error) {
        services.errorReporter.log(error: error)

        // Show the alert after a delay to ensure it doesn't try to display over the
        // closing captcha view.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.coordinator.showAlert(.networkResponseError(error))
        }
    }
}

// MARK: - DuoAuthenticationFlowDelegate

/// An object that is signaled when specific circumstances in the web authentication on flow have been encountered.
///
protocol DuoAuthenticationFlowDelegate: AnyObject {
    /// Called when the web auth flow has been completed successfully.
    ///
    /// - Parameter code: The code that was returned by the single sign on web auth process.
    ///
    func didComplete(code: String)

    /// Called when the single sign on flow encounters an error.
    ///
    /// - Parameter error: The error that was encountered.
    ///
    func duoErrored(error: Error)
}

extension TwoFactorAuthProcessor: DuoAuthenticationFlowDelegate {
    func didComplete(code: String) {
        Task {
            await self.perform(.receivedDuoToken(code))
        }
    }

    func duoErrored(error: Error) {
        // The delay is necessary in order to ensure the alert displays over the WebAuth view.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.handleError(error) {
                self.authenticateWithDuo()
            }
        }
    }

    /// Initiates the DUO 2FA Authentication flow by extracting the auth url from `authMethodsData`.
    ///
    func authenticateWithDuo() {
        guard state.authMethod == .duo || state.authMethod == .duoOrganization,
              let maybeValues = state.authMethodsData["\(state.authMethod.rawValue)"],
              let values = maybeValues,
              let authURLString = values["AuthUrl"]??.stringValue,
              let authURL = URL(string: authURLString) else {
            state.toast = Toast(text: Localizations.duoUnsupported)
            return
        }

        coordinator.navigate(
            to: .duoAuthenticationFlow(authURL),
            context: self
        )
    }

    /// Generically handle an error on the view.
    private func handleError(_ error: Error, _ tryAgain: (() async -> Void)? = nil) {
        // First, hide the loading overlay.
        coordinator.hideLoadingOverlay()

        // Do nothing if the user cancelled.
        if case ASWebAuthenticationSessionError.canceledLogin = error { return }

        // Otherwise, show the alert and log the error.
        coordinator.showAlert(.networkResponseError(error, tryAgain))
        services.errorReporter.log(error: error)
    }
}

// MARK: - DuoCallbackURLComponent

/// A component in the Duo Callback URL.
///
enum DuoCallbackURLComponent: String {
    /// The code parameter.
    case code

    /// The state parameter.
    case state
}
