import AuthenticationServices
import OSLog
import SwiftUI
import UIKit

// MARK: - AuthCoordinatorDelegate

/// An object that is signaled when specific circumstances in the auth flow have been encountered.
///
@MainActor
protocol AuthCoordinatorDelegate: AnyObject {
    /// Called when the auth flow has been completed.
    ///
    func didCompleteAuth()
}

// MARK: - AuthCoordinator

/// A coordinator that manages navigation in the authentication flow.
///
final class AuthCoordinator: NSObject, // swiftlint:disable:this type_body_length
    Coordinator,
    HasStackNavigator,
    HasRouter {
    // MARK: Types

    typealias Router = AnyRouter<AuthEvent, AuthRoute>

    typealias Services = HasAccountAPIService
        & HasAppIdService
        & HasAppSettingsStore
        & HasAuthAPIService
        & HasAuthRepository
        & HasAuthService
        & HasBiometricsRepository
        & HasCaptchaService
        & HasClientAuth
        & HasDeviceAPIService
        & HasEnvironmentService
        & HasErrorReporter
        & HasNFCReaderService
        & HasOrganizationAPIService
        & HasPolicyService
        & HasSettingsRepository
        & HasStateService
        & HasSystemDevice
        & HasTrustDeviceService
        & HasVaultTimeoutService

    // MARK: Properties

    /// A delegate used to communicate with the app extension. This should be passed to any
    /// processors that need to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// The delegate for this coordinator. Used to signal when auth has been completed. This should
    /// be used by the coordinator to communicate to its parent coordinator when auth completes and
    /// the auth flow should be dismissed.
    private weak var delegate: (any AuthCoordinatorDelegate)?

    /// A delegate used to communicate the WebAuthn result when the auth has been completed. This is assigned
    /// on a webAuthn navigation casted from the provided context.
    private weak var webAuthnFlowDelegate: (any WebAuthnFlowDelegate)?

    /// The root navigator used to display this coordinator's interface.
    weak var rootNavigator: (any RootNavigator)?

    /// The router used by this coordinator.
    var router: AnyRouter<AuthEvent, AuthRoute>

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `AuthCoordinator`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - delegate: The delegate for this coordinator. Used to signal when auth has been completed.
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - router: The router used by this coordinator to handle events.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        delegate: AuthCoordinatorDelegate,
        rootNavigator: RootNavigator,
        router: AnyRouter<AuthEvent, AuthRoute>,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.delegate = delegate
        self.rootNavigator = rootNavigator
        self.router = router
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: AuthRoute, context: AnyObject?) { // swiftlint:disable:this function_body_length
        switch route {
        case let .alert(alert):
            showAlert(alert)
        case let .captcha(url, callbackUrlScheme):
            showCaptcha(
                url: url,
                callbackUrlScheme: callbackUrlScheme,
                delegate: context as? CaptchaFlowDelegate
            )
        case .complete:
            if stackNavigator?.isPresenting == true {
                stackNavigator?.dismiss {
                    self.delegate?.didCompleteAuth()
                }
            } else {
                delegate?.didCompleteAuth()
            }
        case .createAccount:
            showCreateAccount()
        case .dismiss:
            stackNavigator?.dismiss()
        case let .duoAuthenticationFlow(authURL):
            showDuo2FA(authURL: authURL, delegate: context as? DuoAuthenticationFlowDelegate)
        case let .enterpriseSingleSignOn(email):
            showEnterpriseSingleSignOn(email: email)
        case .landing:
            showLanding()
        case let .login(username):
            showLogin(username)
        case .showLoginDecryptionOptions:
            showLoginDecryptionOptions()
        case let .loginWithDevice(email, type):
            showLoginWithDevice(email: email, type: type, isAuthenticated: context is LoginDecryptionOptionsProcessor)
        case let .masterPasswordHint(username):
            showMasterPasswordHint(for: username)
        case let .selfHosted(region):
            showSelfHostedView(delegate: context as? SelfHostedProcessorDelegate, currentRegion: region)
        case let .setMasterPassword(organizationIdentifier):
            showSetMasterPassword(organizationIdentifier: organizationIdentifier)
        case let .singleSignOn(callbackUrlScheme, state, url):
            showSingleSignOn(
                callbackUrlScheme: callbackUrlScheme,
                delegate: context as? SingleSignOnFlowDelegate,
                state: state,
                url: url
            )
        case let .twoFactor(email, unlockMethod, authMethodsData):
            showTwoFactorAuth(email: email, unlockMethod: unlockMethod, authMethodsData: authMethodsData)
        case .updateMasterPassword:
            showUpdateMasterPassword()
        case let .webAuthn(rpId, challenge, allowCredentialIds, userVerificationPreference):
            webAuthnFlowDelegate = context as? WebAuthnFlowDelegate
            showWebAuthn(
                rpId: rpId,
                challenge: challenge,
                credentialIds: allowCredentialIds,
                userVerificationPreference: userVerificationPreference
            )
        case let .vaultUnlock(
            account,
            animated,
            attemptAutomaticBiometricUnlock,
            didSwitch
        ):
            showVaultUnlock(
                account: account,
                animated: animated,
                attemptAutmaticBiometricUnlock: attemptAutomaticBiometricUnlock,
                didSwitchAccountAutomatically: didSwitch
            )
        }
    }

    func start() {
        guard let stackNavigator else { return }
        rootNavigator?.show(child: stackNavigator)
    }

    // MARK: Private Methods

    /// Configures the app with an active account.
    ///
    /// - Parameter shouldSwitchAutomatically: Should the app switch to the next available account
    ///     if there is no active account?
    /// - Returns: The account model currently set as active.
    ///
    private func configureActiveAccount(shouldSwitchAutomatically: Bool) async throws -> Account {
        if let active = try? await services.stateService.getActiveAccount() {
            return active
        }
        guard shouldSwitchAutomatically,
              let alternate = try await services.stateService.getAccounts().first else {
            throw StateServiceError.noActiveAccount
        }
        return try await services.authRepository.setActiveAccount(userId: alternate.profile.userId)
    }

    /// Shows the captcha screen.
    ///
    /// - Parameters:
    ///   - url: The URL for the captcha screen.
    ///   - callbackUrlScheme: The callback url scheme for this application.
    ///   - delegate: A `CaptchaFlowDelegate` object that is notified when the captcha flow succeeds or fails.
    ///
    private func showCaptcha(
        url: URL,
        callbackUrlScheme: String,
        delegate: CaptchaFlowDelegate?
    ) {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackUrlScheme
        ) { url, error in
            if let url,
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItem = components.queryItems?.first(where: { $0.name == "token" }),
               let token = queryItem.value {
                delegate?.captchaCompleted(token: token)
            } else if let error {
                delegate?.captchaErrored(error: error)
            }
        }

        // prefersEphemeralWebBrowserSession should be false to allow access to the hCaptcha accessibility
        // cookie set in the default browser: https://www.hcaptcha.com/accessibility
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = self
        session.start()
    }

    /// Shows the create account screen.
    ///
    private func showCreateAccount() {
        let view = CreateAccountView(
            store: Store(
                processor: CreateAccountProcessor(
                    coordinator: asAnyCoordinator(),
                    services: services,
                    state: CreateAccountState()
                )
            )
        )
        let navController = UINavigationController(rootViewController: UIHostingController(rootView: view))
        stackNavigator?.present(navController)
    }

    /// Shows the Duo 2FA screen.
    ///
    /// - Parameters:
    ///   - url: The URL for the single sign on web auth session.
    ///   - delegate: A `DuoAuthenticationFlowDelegate` object that is notified when the duo flow succeeds or fails.
    ///
    private func showDuo2FA(
        authURL url: URL,
        delegate: DuoAuthenticationFlowDelegate?
    ) {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: services.authService.callbackUrlScheme
        ) { callbackURL, error in
            if let error {
                delegate?.duoErrored(error: error)
                return
            }
            guard let callbackURL,
                  let components = URLComponents(
                      url: callbackURL,
                      resolvingAgainstBaseURL: false
                  ),
                  let queryItems = components.queryItems,
                  let code = queryItems.first(where: { component in
                      component.name == DuoCallbackURLComponent.code.rawValue
                  })?.value,
                  let state = queryItems.first(where: { component in
                      component.name == DuoCallbackURLComponent.state.rawValue
                  })?.value else {
                delegate?.duoErrored(error: AuthError.unableToDecodeDuoResponse)
                return
            }

            let duoCode: String = code + "|" + state
            delegate?.didComplete(code: duoCode)
        }

        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = self
        session.start()
    }

    /// Shows the enterprise single sign-on screen.
    ///
    /// - Parameter email: The user's email address.
    ///
    private func showEnterpriseSingleSignOn(email: String) {
        let processor = SingleSignOnProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: SingleSignOnState(email: email)
        )
        let store = Store(processor: processor)
        let view = SingleSignOnView(store: store)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        stackNavigator?.present(navigationController)
    }

    /// Shows the landing screen.
    ///
    private func showLanding() {
        guard let stackNavigator else { return }
        if stackNavigator.popToRoot(animated: UI.animated).isEmpty {
            let processor = LandingProcessor(
                coordinator: asAnyCoordinator(),
                services: services,
                state: LandingState()
            )
            let store = Store(processor: processor)
            let view = LandingView(store: store)
            stackNavigator.replace(view, animated: false)
        }
    }

    /// Shows the login screen. If the create account flow is being presented it will be dismissed
    /// and the login screen will be pushed
    ///
    /// - Parameter username: The user's username.
    ///
    private func showLogin(_ username: String) {
        guard let stackNavigator else { return }
        let isPresenting = stackNavigator.rootViewController?.presentedViewController != nil

        let environmentUrls = EnvironmentUrls(
            environmentUrlData: services.appSettingsStore.preAuthEnvironmentUrls ?? EnvironmentUrlData()
        )

        let state = LoginState(
            serverURLString: environmentUrls.webVaultURL.host ?? "",
            username: username
        )

        let processor = LoginProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: state
        )
        let store = Store(processor: processor)
        let view = LoginView(store: store)
        let viewController = UIHostingController(rootView: view)

        // When hiding the back button, we need to use both SwiftUI's method alongside UIKit's, otherwise the
        // back button might flash on screen while the screen is being pushed.
        viewController.navigationItem.hidesBackButton = true
        stackNavigator.push(viewController)

        if isPresenting {
            stackNavigator.dismiss()
        }
    }

    /// Shows the login with device screen.
    ///
    /// - Parameter email: The user's email.
    ///
    private func showLoginWithDevice(email: String, type: AuthRequestType, isAuthenticated: Bool) {
        let processor = LoginWithDeviceProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: LoginWithDeviceState(email: email, requestType: type, isAuthenticated: isAuthenticated)
        )
        let store = Store(processor: processor)
        let view = LoginWithDeviceView(store: store)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        stackNavigator?.present(navigationController)
    }

    /// Shows the login decryption options screen.
    ///
    /// - Parameter email: The user's email.
    ///
    private func showLoginDecryptionOptions() {
        let processor = LoginDecryptionOptionsProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: LoginDecryptionOptionsState()
        )
        let store = Store(processor: processor)
        let view = LoginDecryptionOptionsView(store: store)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        stackNavigator?.present(navigationController)
    }

    /// Shows the master password hint screen for the provided username.
    ///
    /// - Parameter username: The username to get the password hint for.
    ///
    private func showMasterPasswordHint(for username: String) {
        let processor = PasswordHintProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: PasswordHintState(emailAddress: username)
        )
        let store = Store(processor: processor)
        let view = PasswordHintView(store: store)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        stackNavigator?.present(navigationController)
    }

    /// Shows the self-hosted settings view.
    ///
    /// - Parameters:
    ///   - delegate: A delegate of `SelfHostedProcessor` that is notified
    ///     when the user saves their environment settings.
    ///   - currentRegion: The user's region prior to showing the self-hosted settings view.
    ///
    private func showSelfHostedView(delegate: SelfHostedProcessorDelegate?, currentRegion: RegionType) {
        let preAuthEnvironmentUrls = services.appSettingsStore.preAuthEnvironmentUrls ?? EnvironmentUrlData()
        var state = SelfHostedState()

        if currentRegion == .selfHosted {
            state = SelfHostedState(
                apiServerUrl: preAuthEnvironmentUrls.api?.sanitized.description ?? "",
                iconsServerUrl: preAuthEnvironmentUrls.icons?.sanitized.description ?? "",
                identityServerUrl: preAuthEnvironmentUrls.identity?.sanitized.description ?? "",
                serverUrl: preAuthEnvironmentUrls.base?.sanitized.description ?? "",
                webVaultServerUrl: preAuthEnvironmentUrls.webVault?.sanitized.description ?? ""
            )
        }

        let processor = SelfHostedProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            state: state
        )
        let view = SelfHostedView(store: Store(processor: processor))
        let navController = UINavigationController(rootViewController: UIHostingController(rootView: view))
        stackNavigator?.present(navController)
    }

    /// Shows the set master password view.
    ///
    /// - Parameter organizationIdentifier: The organization's identifier.
    ///
    private func showSetMasterPassword(organizationIdentifier: String) {
        let processor = SetMasterPasswordProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: SetMasterPasswordState(organizationIdentifier: organizationIdentifier)
        )
        let view = SetMasterPasswordView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isModalInPresentation = true

        stackNavigator?.present(navigationController)
    }

    /// Shows the single sign on screen.
    ///
    /// - Parameters:
    ///   - callbackUrlScheme: The callback url scheme for this application.
    ///   - delegate: A `SingleSignOnFlowDelegate` object that is notified when the single sign on flow succeeds or
    ///     fails.
    ///   - state: The password that the response has to match.
    ///   - url: The URL for the single sign on web auth session.
    ///
    private func showSingleSignOn(
        callbackUrlScheme: String,
        delegate: SingleSignOnFlowDelegate?,
        state: String,
        url: URL
    ) {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackUrlScheme
        ) { url, error in
            if let error {
                delegate?.singleSignOnErrored(error: error)
                return
            }
            guard let url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let stateItem = components.queryItems?.first(where: { $0.name == "state" }),
                  stateItem.value == state,
                  let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
                  let code = codeItem.value
            else {
                delegate?.singleSignOnErrored(error: AuthError.unableToDecodeSSOResponse)
                return
            }
            delegate?.singleSignOnCompleted(code: code)
        }

        // prefersEphemeralWebBrowserSession should be false to allow access to the hCaptcha accessibility
        // cookie set in the default browser: https://www.hcaptcha.com/accessibility
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = self
        session.start()
    }

    /// Show the two factor authentication view.
    ///
    /// - Parameters:
    ///   - email: The user's email.
    ///   - unlockMethod: The method used to unlock the vault after two-factor completes successfully.
    ///   - authMethodsData: The data required for the two-factor flow.
    ///
    private func showTwoFactorAuth(
        email: String,
        unlockMethod: TwoFactorUnlockMethod?,
        authMethodsData: AuthMethodsData
    ) {
        let state = TwoFactorAuthState(
            authMethodsData: authMethodsData,
            email: email,
            unlockMethod: unlockMethod
        )
        let processor = TwoFactorAuthProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: state
        )

        let view = TwoFactorAuthView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        stackNavigator?.present(navigationController)
    }

    /// Shows the update master password view.
    private func showUpdateMasterPassword() {
        let processor = UpdateMasterPasswordProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: .init()
        )
        let store = Store(processor: processor)
        let view = UpdateMasterPasswordView(
            store: store
        )
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isModalInPresentation = true

        stackNavigator?.present(navigationController)
    }

    /// Show the WebAuthn two factor authentication view.
    ///
    /// - Parameters:
    ///   - rpId: Identifier for the relying party.
    ///   - challenge: Challenge sent to be solve by an authenticator.
    ///   - credentialsIds: Identifiers for the allowed credentials to be used to solve the challenge
    ///   - userVerificationPreference: specifies which type of user verification is needed to complete the attestation
    ///
    func showWebAuthn(rpId: String, challenge: Data, credentialIds: [Data], userVerificationPreference: String) {
        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let platformKeyRequest = platformProvider.createCredentialAssertionRequest(challenge: challenge)
        platformKeyRequest.userVerificationPreference =
            ASAuthorizationPublicKeyCredentialUserVerificationPreference(userVerificationPreference)

        let securityKeyProvider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let securityKeyRequest = securityKeyProvider.createCredentialAssertionRequest(challenge: challenge)
        securityKeyRequest.userVerificationPreference =
            ASAuthorizationPublicKeyCredentialUserVerificationPreference(userVerificationPreference)

        for credentialId in credentialIds {
            securityKeyRequest.allowedCredentials.append(
                ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor(
                    credentialID: credentialId,
                    transports: ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport.allSupported
                )
            )
            platformKeyRequest.allowedCredentials.append(ASAuthorizationPlatformPublicKeyCredentialDescriptor(
                credentialID: credentialId)
            )
        }

        let authController = ASAuthorizationController(authorizationRequests: [securityKeyRequest, platformKeyRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
    }

    /// Shows the vault unlock view.
    ///
    /// - Parameters:
    ///   - account: The active account.
    ///   - animated: Whether to animate the transition.
    ///   - attemptAutmaticBiometricUnlock: Whether to the processor should attempt a biometric unlock on appear.
    ///   - didSwitchAccountAutomatically: A flag indicating if the active account was switched automatically.
    ///
    private func showVaultUnlock(
        account: Account,
        animated: Bool,
        attemptAutmaticBiometricUnlock: Bool,
        didSwitchAccountAutomatically: Bool
    ) {
        let processor = VaultUnlockProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: asAnyCoordinator(),
            services: services,
            state: VaultUnlockState(account: account)
        )
        processor.shouldAttemptAutomaticBiometricUnlock = attemptAutmaticBiometricUnlock
        let view = VaultUnlockView(store: Store(processor: processor))
        stackNavigator?.replace(view, animated: animated)
        if didSwitchAccountAutomatically {
            processor.state.toast = Toast(text: Localizations.accountSwitchedAutomatically)
        }
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding

extension AuthCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        stackNavigator?.rootViewController?.view.window ?? UIWindow()
    }
}

// MARK: ASAuthorizationControllerPresentationContextProviding

extension AuthCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        stackNavigator?.rootViewController?.view.window ?? UIWindow()
    }
}

// MARK: ASAuthorizationControllerDelegate

/// Delegate used to handle ASAuthorization flows
extension AuthCoordinator: ASAuthorizationControllerDelegate {
    /// Data structure to be sent to the server
    struct WebAuthnRequest: Codable {
        let id: String
        let rawId: String
        let type: String
        let response: AttestationData
    }

    /// struct to hold information about the attestation created by the authenticator
    struct AttestationData: Codable {
        let authenticatorData: String
        let clientDataJson: String
        let signature: String
    }

    /// Handle ASAuthorization flow where the attestation did complete with success
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        if let credential = authorization.credential as? ASAuthorizationPublicKeyCredentialAssertion {
            let rawClientDataJSON = credential.rawClientDataJSON.base64EncodedString().urlEncoded()
            let credentialID = credential.credentialID.base64EncodedString().urlEncoded()
            let rawAuthenticatorData = credential.rawAuthenticatorData.base64EncodedString().urlEncoded()
            let signature = credential.signature.base64EncodedString().urlEncoded()
            let request = WebAuthnRequest(
                id: credentialID,
                rawId: credential.credentialID.base64EncodedString(),
                type: "public-key",
                response: AttestationData(
                    authenticatorData: rawAuthenticatorData,
                    clientDataJson: rawClientDataJSON,
                    signature: signature
                )
            )

            guard let jsonData = try? JSONEncoder().encode(request),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                webAuthnFlowDelegate?.webAuthnErrored(error: WebAuthnError.unableToCreateAttestationVerification)
                return
            }

            webAuthnFlowDelegate?.webAuthnCompleted(
                token: jsonString
            )
        }
    }

    /// Handle errors during the creation of the attestation
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        webAuthnFlowDelegate?.webAuthnErrored(error: error)
    }
} // swiftlint:disable:this file_length
