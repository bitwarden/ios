import AuthenticationServices
import BitwardenKit
import BitwardenResources
import CryptoKit
import Foundation

/// Errors thrown by `TwoFactorAuthProcessor`.
///
enum TwoFactorAuthError: Error {
    /// The organization's identifier is missing, but required for Key Connector unlock.
    case missingOrgIdentifier
}

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
        case .appeared:
            guard state.authMethod == .email, !state.deviceVerificationRequired else { return }
            await sendVerificationCodeEmail()
        case .beginDuoAuth:
            authenticateWithDuo()
        case .beginWebAuthn:
            authenticateWithWebAuthn()
        case .continueTapped:
            await login()
        case .listenForNFC:
            await listenForNFC()
        case let .receivedDuoToken(duoToken):
            state.verificationCode = duoToken
            await login()
        case .resendEmailTapped:
            await sendVerificationCodeEmail()
        case .tryAgainTapped:
            services.nfcReaderService.startReading()
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
            state.continueEnabled = !newValue.isEmpty
        }
    }

    // MARK: Private Methods

    /// Update the selected auth method or launch the web view for the recovery code.
    private func handleAuthMethodSelected(_ authMethod: TwoFactorAuthMethod) {
        switch authMethod {
        case .recoveryCode:
            state.url = services.environmentService.recoveryCodeURL
        case .email:
            Task { await sendVerificationCodeEmail() }
            state.authMethod = authMethod
        default:
            state.authMethod = authMethod
        }
    }

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
            await coordinator.showErrorAlert(error: error)
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
            await coordinator.showErrorAlert(error: error)
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
            let unlockMethod = try await services.authService.loginWithTwoFactorCode(
                email: state.email,
                code: code,
                method: state.authMethod,
                remember: state.isRememberMeOn,
                captchaToken: captchaToken
            )

            try await tryToUnlockVault(unlockMethod)
        } catch let error as InputValidationError {
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
        } catch let IdentityTokenRequestError.captchaRequired(hCaptchaSiteCode) {
            await launchCaptchaFlow(with: hCaptchaSiteCode)
        } catch IdentityTokenRequestError.newDeviceNotVerified {
            coordinator.showAlert(.defaultAlert(title: Localizations.invalidVerificationCode))
        } catch let authError as AuthError {
            if authError == .requireSetPassword,
               let orgId = state.orgIdentifier {
                coordinator.navigate(to: .setMasterPassword(organizationIdentifier: orgId))
            } else if authError == .requireUpdatePassword {
                coordinator.navigate(to: .updateMasterPassword)
            } else if authError == .requireDecryptionOptions,
                      let orgId = state.orgIdentifier {
                coordinator.navigate(to: .showLoginDecryptionOptions(organizationIdentifier: orgId))
            } else {
                coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            }
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }

    /// Sends the verification code email.
    private func sendVerificationCodeEmail() async {
        guard state.authMethod == .email else { return }
        do {
            coordinator.showLoadingOverlay(title: Localizations.submitting)

            if state.deviceVerificationRequired {
                try await services.authService.resendNewDeviceOtp()
            } else {
                try await services.authService.resendVerificationCodeEmail()
            }

            coordinator.hideLoadingOverlay()
            state.toast = Toast(title: Localizations.verificationEmailSent)
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
        guard let providersAvailable = state.authMethodsData.providersAvailable else { return }
        // Determine all the available auth methods for the user, adding on the recovery code
        // which is always available.
        var availableMethods = providersAvailable
            .sorted()
            .compactMap(TwoFactorAuthMethod.init)
        availableMethods.append(.recoveryCode)
        state.availableAuthMethods = availableMethods

        // The default two-factor auth provider is the one with the highest priority.
        let preferredMethod = availableMethods.max(by: { $1.priority > $0.priority })
        state.authMethod = preferredMethod ?? .email

        // If email is one of the options, then parse the data to get the email to display.
        if availableMethods.contains(.email),
           let emailData = state.authMethodsData.email {
            state.displayEmail = emailData.email ?? state.email
        }
    }

    /// Try to unlock the vault with the unlock method.
    private func tryToUnlockVault(_ unlockMethod: LoginUnlockMethod) async throws {
        if let unlockMethod = state.unlockMethod {
            try await unlockVaultWithMethod(unlockMethod: unlockMethod)
            coordinator.hideLoadingOverlay()
            await coordinator.handleEvent(.didCompleteAuth)
        } else {
            switch unlockMethod {
            case .deviceKey:
                try await services.authRepository.unlockVaultWithDeviceKey()
                await coordinator.handleEvent(.didCompleteAuth)
            case let .masterPassword(account):
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
            case let .keyConnector(keyConnectorUrl):
                guard let orgIdentifier = state.orgIdentifier else {
                    throw TwoFactorAuthError.missingOrgIdentifier
                }
                try await services.authRepository.unlockVaultWithKeyConnectorKey(
                    keyConnectorURL: keyConnectorUrl,
                    orgIdentifier: orgIdentifier
                )
                await coordinator.handleEvent(.didCompleteAuth)
            }
        }
    }

    /// Attempts to unlock the user's vault with the specified unlock method.
    ///
    /// - Parameter unlockMethod: The method used to unlock the vault.
    ///
    private func unlockVaultWithMethod(unlockMethod: TwoFactorUnlockMethod) async throws {
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
        guard (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue else { return }

        services.errorReporter.log(error: error)

        // Show the alert after a delay to ensure it doesn't try to display over the
        // closing captcha view.
        Task { @MainActor in
            try await Task.sleep(forSeconds: UI.duration(0.6))
            await coordinator.showErrorAlert(error: error)
        }
    }
}

// MARK: - DuoAuthenticationFlowDelegate

/// An object that is signaled when specific circumstances in the web authentication on flow have been encountered.
///
@MainActor
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
        Task { @MainActor in
            try await Task.sleep(forSeconds: UI.duration(0.5))
            await self.handleError(error) {
                self.authenticateWithDuo()
            }
        }
    }

    /// Initiates the DUO 2FA Authentication flow by extracting the auth url from `authMethodsData`.
    ///
    func authenticateWithDuo() {
        var maybeAuthURL: String?
        if state.authMethod == .duo,
           let duoData = state.authMethodsData.duo,
           let authURLStringValue = duoData.authUrl {
            maybeAuthURL = authURLStringValue
        }

        if state.authMethod == .duoOrganization,
           let duoOrgData = state.authMethodsData.organizationDuo,
           let authURLStringValue = duoOrgData.authUrl {
            maybeAuthURL = authURLStringValue
        }

        guard let authURLValue = maybeAuthURL,
              let authURL = URL(string: authURLValue) else {
            state.toast = Toast(
                // swiftlint:disable:next line_length
                title: Localizations.errorConnectingWithTheDuoServiceUseADifferentTwoStepLoginMethodOrContactDuoForAssistance
            )
            return
        }

        coordinator.navigate(
            to: .duoAuthenticationFlow(authURL),
            context: self
        )
    }

    /// Generically handle an error on the view.
    private func handleError(_ error: Error, _ tryAgain: (() async -> Void)? = nil) async {
        // First, hide the loading overlay.
        coordinator.hideLoadingOverlay()

        // Do nothing if the user cancelled.
        if case ASWebAuthenticationSessionError.canceledLogin = error { return }

        // Otherwise, show the alert and log the error.
        await coordinator.showErrorAlert(error: error, tryAgain: tryAgain)
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

// MARK: WebAuthnFlowDelegate

/// An object that is signaled when specific circumstances in the WebAuthn flow have been encountered.
///
@MainActor
protocol WebAuthnFlowDelegate: AnyObject {
    /// Called when the WebAuthn flow has been completed successfully.
    ///
    /// - Parameter token: The token that is computed from the attestation data.
    ///
    func webAuthnCompleted(token: String)

    /// Called when the WebAuthn flow encounters an error.
    ///
    /// - Parameter error: The error that was encountered.
    ///
    func webAuthnErrored(error: Error)
}

public enum WebAuthnError: Error {
    case requiredParametersMissing
    case unableToCreateAttestationVerification
    case unableToDecodeCredential
    case unableToGenerateUrl
}

extension TwoFactorAuthProcessor: WebAuthnFlowDelegate {
    struct WebAuthnConnectorData: Codable, Equatable {
        let btnReturnText: String
        let btnText: String
        let callbackUri: URL
        let data: String
        let headerText: String
    }

    func webAuthnCompleted(token: String) {
        Task {
            state.verificationCode = token
            await login()
        }
    }

    func webAuthnErrored(error: Error) {
        // The delay is necessary in order to ensure the alert displays over the WebAuthn view.
        Task { @MainActor in
            try await Task.sleep(forSeconds: UI.duration(0.5))
            await self.handleError(error) {
                self.authenticateWithWebAuthn()
            }
        }
    }

    /// Initiates the WebAuthn 2FA Authentication flow
    ///
    private func authenticateWithWebAuthn() {
        do {
            if let webAuthnProvider = state.authMethodsData.webAuthn,
               let rpID = webAuthnProvider.rpId,
               let userVerificationPreference = webAuthnProvider.userVerification,
               let challenge = webAuthnProvider.challenge,
               let challengeUrlDecode = try? challenge.urlDecoded(),
               let challengeData = Data(base64Encoded: challengeUrlDecode),
               let allowCredentials = webAuthnProvider.allowCredentials {
                if services.environmentService.region == .selfHosted {
                    try coordinator.navigate(
                        to: .webAuthnSelfHosted(
                            webAuthnUrl(
                                baseURL: services.environmentService.webVaultURL,
                                data: webAuthnProvider,
                                headerText: Localizations.fido2Title,
                                buttonText: Localizations.fido2AuthenticateWebAuthn,
                                returnButtonText: Localizations.fido2ReturnToApp
                            )
                        ),
                        context: self
                    )
                } else {
                    try coordinator.navigate(
                        to: .webAuthn(rpid: rpID,
                                      challenge: challengeData,
                                      allowCredentialIDs: allowCredentials.map { credential in
                                          guard let id = credential.id,
                                                let idUrlDecoded = try? id.urlDecoded(),
                                                let idData = Data(base64Encoded: idUrlDecoded) else {
                                              throw WebAuthnError.unableToDecodeCredential
                                          }
                                          return idData
                                      },
                                      userVerificationPreference: userVerificationPreference),
                        context: self
                    )
                }
            } else {
                throw WebAuthnError.requiredParametersMissing
            }
        } catch {
            coordinator.showAlert(.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.thereWasAnErrorStartingWebAuthnTwoFactorAuthentication
            ))
            services.errorReporter.log(error: error)
        }
    }

    /// Generates a URL to display a WebAuthn challenge for Self-Hosted vault authentication.
    ///
    private func webAuthnUrl(
        baseURL: URL,
        data: WebAuthn,
        headerText: String,
        buttonText: String,
        returnButtonText: String
    ) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys // for consistency
        let callbackUrlString = "bitwarden://webauthn-callback"
        let encodedCallback = callbackUrlString.urlEncoded()
        let connectorData = try WebAuthnConnectorData(
            btnReturnText: returnButtonText,
            btnText: buttonText,
            callbackUri: URL(string: callbackUrlString)!,
            data: String(data: encoder.encode(data), encoding: .utf8)!,
            headerText: headerText
        )
        let jsonData = try encoder.encode(connectorData)
        let base64string = jsonData.base64EncodedString()

        guard let url = baseURL
            .appendingPathComponent("/webauthn-mobile-connector.html")
            .appending(queryItems: [
                URLQueryItem(name: "data", value: base64string),
                URLQueryItem(name: "parent", value: encodedCallback),
                URLQueryItem(name: "v", value: "2"),
            ]) else {
            throw WebAuthnError.unableToGenerateUrl
        }
        return url
    }
} // swiftlint:disable:this file_length
