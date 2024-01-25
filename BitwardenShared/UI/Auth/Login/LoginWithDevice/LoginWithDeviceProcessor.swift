import Foundation

// MARK: - LoginWithDeviceProcessor

/// The processor used to manage state and handle actions for the `LoginWithDeviceView`.
///
final class LoginWithDeviceProcessor: StateProcessor<
    LoginWithDeviceState,
    LoginWithDeviceAction,
    LoginWithDeviceEffect
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasAuthService
        & HasCaptchaService
        & HasErrorReporter

    // MARK: Properties

    /// The approved login request (stored in case the login flow is interrupted by a captcha request).
    private var approvedRequest: LoginRequest?

    /// The coordinator used for navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

    /// The services used by this processor.
    private let services: Services

    /// The timer used to automatically check for a response to the login request.
    private var checkTimer: Timer?

    // MARK: Initialization

    /// Initializes an `LoginWithDeviceProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute>,
        services: Services,
        state: LoginWithDeviceState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    deinit {
        checkTimer?.invalidate()
    }

    // MARK: Methods

    override func perform(_ effect: LoginWithDeviceEffect) async {
        switch effect {
        case .appeared,
             .resendNotification:
            await sendLoginWithDeviceRequest()
        }
    }

    override func receive(_ action: LoginWithDeviceAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        }
    }

    // MARK: Private Methods

    /// Create and send the login with device notification and display the resulting fingerprint.
    ///
    private func sendLoginWithDeviceRequest() async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            coordinator.showLoadingOverlay(title: Localizations.loading)

            let result = try await services.authService.initiateLoginWithDevice(email: state.email)
            state.fingerprintPhrase = result.fingerprint
            state.requestId = result.requestId

            // Start checking for a response every few seconds.
            setCheckTimer()
        } catch {
            coordinator.showAlert(.networkResponseError(error) { await self.appeared() })
            services.errorReporter.log(error: error)
        }
    }

    /// Attempt to login.
    private func attemptLogin(with request: LoginRequest?, captchaToken: String? = nil) async {
        do {
            coordinator.showLoadingOverlay(title: Localizations.loggingIn)
            // Used the cached request if it's nil (for example, if the captcha flow just completed).
            guard let request = request ?? approvedRequest else { return }
            approvedRequest = request

            // Attempt to login.
            let temp = try await services.authService.loginWithDevice(
                request,
                email: state.email,
                captchaToken: captchaToken
            )

            // Attempt to unlock the vault.
            try await services.authRepository.unlockVaultFromLoginWithDevice(privateKey: temp.0, key: temp.1)

            // If login was successful, navigate to the vault.
            coordinator.hideLoadingOverlay()
            coordinator.navigate(to: .dismiss)
            coordinator.navigate(to: .complete)
        } catch {
            handleError(error) { await self.attemptLogin(with: request) }
        }
    }

    /// Check for a response to the login request.
    private func checkForResponse() {
        Task {
            do {
                // Get the updated request.
                guard let requestId = self.state.requestId else { throw AuthError.missingData }
                let request = try await self.services.authService.checkPendingLoginRequest(withId: requestId)

                // Show an alert and dismiss the view if the request has expired.
                guard !request.isExpired else {
                    return coordinator.showAlert(.requestExpired {
                        self.coordinator.navigate(to: .dismiss)
                    })
                }

                // Keep waiting if the request hasn't been answered yet.
                guard request.isAnswered else { return }

                // If the request has been denied, show an alert and dismiss the view.
                if request.requestApproved == false {
                    coordinator.showAlert(.requestDenied {
                        self.coordinator.navigate(to: .dismiss)
                    })
                    return
                } else if request.requestApproved == true {
                    // Otherwise, if the request has been approved, stop the update timer
                    // and attempt to authenticate.
                    self.checkTimer?.invalidate()
                    await self.attemptLogin(with: request)
                }
            } catch {
                self.coordinator.showAlert(.networkResponseError(error))
                self.services.errorReporter.log(error: error)
            }
        }
    }

    /// Generically handle an error on the view.
    private func handleError(_ error: Error, _ tryAgain: (() async -> Void)? = nil) {
        coordinator.hideLoadingOverlay()

        // Handle a captcha or two-factor error.
        if let identityTokenError = error as? IdentityTokenRequestError {
            switch identityTokenError {
            case let .captchaRequired(token):
                launchCaptchaFlow(with: token)
            case let .twoFactorRequired(authMethodsData, _, _):
                coordinator.navigate(to: .twoFactor(state.email, nil, authMethodsData))
            }
            return
        }

        coordinator.showAlert(.networkResponseError(error, tryAgain))
        services.errorReporter.log(error: error)
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

    /// Set or reset the auto-check timer.
    private func setCheckTimer() {
        checkTimer?.invalidate()

        // Set the timer to auto-check for a response every four seconds.
        checkTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            self.checkForResponse()
        }
    }
}

// MARK: CaptchaFlowDelegate

extension LoginWithDeviceProcessor: CaptchaFlowDelegate {
    func captchaCompleted(token: String) {
        Task {
            await attemptLogin(with: nil, captchaToken: token)
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
