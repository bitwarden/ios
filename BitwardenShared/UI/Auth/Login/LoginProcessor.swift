import BitwardenSdk

// MARK: - CaptchaFlowDelegate

/// An object that is signaled when specific circumstances in the captcha flow have been encountered.
///
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

    typealias Services = HasAccountAPIService
        & HasAppIdService
        & HasAuthAPIService
        & HasCaptchaService
        & HasClientAuth
        & HasSystemDevice

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<AuthRoute>

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
        coordinator: AnyCoordinator<AuthRoute>,
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
        case .loginWithMasterPasswordPressed:
            await loginWithMasterPassword()
        }
    }

    override func receive(_ action: LoginAction) {
        switch action {
        case .enterpriseSingleSignOnPressed:
            coordinator.navigate(to: .enterpriseSingleSignOn)
        case .getMasterPasswordHintPressed:
            coordinator.navigate(to: .masterPasswordHint)
        case .loginWithDevicePressed:
            coordinator.navigate(to: .loginWithDevice)
        case let .masterPasswordChanged(newValue):
            state.masterPassword = newValue
        case .morePressed:
            coordinator.navigate(to: .loginOptions)
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
    private func launchCaptchaFlow(with siteKey: String) {
        do {
            let callbackUrlScheme = services.captchaService.callbackUrlScheme
            let url = try services.captchaService.generateCaptchaUrl(with: siteKey)
            coordinator.navigate(
                to: .captcha(
                    url: url,
                    callbackUrlScheme: callbackUrlScheme
                ),
                context: self
            )
        } catch {
            // TODO: BIT-709 Add proper error handling
            print(error)
        }
    }

    /// Attempts to log the user in with the email address and password values found in `state`.
    ///
    private func loginWithMasterPassword(captchaToken: String? = nil) async {
        do {
            let response = try await services.accountAPIService.preLogin(email: state.username)

            let kdf: Kdf
            switch response.kdf {
            case .argon2id:
                kdf = .argon2id(
                    iterations: NonZeroU32(response.kdfIterations),
                    memory: NonZeroU32(response.kdfMemory ?? 1),
                    parallelism: NonZeroU32(response.kdfParallelism ?? 1)
                )
            case .pbkdf2sha256:
                kdf = .pbkdf2(iterations: NonZeroU32(response.kdfIterations))
            }

            let hashedPassword = try await services.clientAuth.hashPassword(
                email: state.username,
                password: state.masterPassword,
                kdfParams: kdf
            )

            let appID = await services.appIdService.getOrCreateAppId()
            let identityTokenRequest = IdentityTokenRequestModel(
                authenticationMethod: .password(
                    username: state.username,
                    password: hashedPassword
                ),
                captchaToken: captchaToken,
                deviceInfo: DeviceInfo(
                    identifier: appID,
                    name: services.systemDevice.modelIdentifier
                )
            )
            let identityToken = try await services.authAPIService.getIdentityToken(identityTokenRequest)
            print("TOKEN: \(identityToken)")

            // TODO: BIT-165 Store the access token.
            coordinator.navigate(to: .complete)
        } catch {
            if let error = error as? IdentityTokenRequestError {
                switch error {
                case let .captchaRequired(hCaptchaSiteCode):
                    launchCaptchaFlow(with: hCaptchaSiteCode)
                }
            } else {
                // TODO: BIT-709 Add proper error handling for non-captcha errors.
            }
        }
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
        // TODO: BIT-709 Add proper error handling.
        print(error)
    }
}
