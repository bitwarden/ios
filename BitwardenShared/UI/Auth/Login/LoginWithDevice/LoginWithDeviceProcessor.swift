import AuthenticationServices
import BitwardenResources
@preconcurrency import BitwardenSdk
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
        & HasConfigService
        & HasErrorReporter

    // MARK: Properties

    /// The approved login request (stored in case the login flow is interrupted by a captcha request).
    private var approvedRequest: LoginRequest?

    /// The response from creating an auth request for logging in with another device.
    private var authRequestResponse: AuthRequestResponse?

    /// The coordinator used for navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by this processor.
    private let services: Services

    /// The timer used to automatically check for a response to the login request.
    private(set) var checkTimer: Timer?

    // MARK: Initialization

    /// Initializes an `LoginWithDeviceProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
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

            let result = try await services.authService.initiateLoginWithDevice(
                email: state.email,
                type: state.requestType
            )
            state.fingerprintPhrase = result.authRequestResponse.fingerprint
            state.requestId = result.requestId
            authRequestResponse = result.authRequestResponse

            // Start checking for a response every few seconds.
            setCheckTimer()
        } catch {
            await coordinator.showErrorAlert(error: error) {
                await self.sendLoginWithDeviceRequest()
            }
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
            let (privateKey, key) = try await services.authService.loginWithDevice(
                request,
                email: state.email,
                isAuthenticated: state.isAuthenticated,
                captchaToken: captchaToken
            )

            // Attempt to unlock the vault.
            try await services.authRepository.unlockVaultFromLoginWithDevice(
                privateKey: privateKey,
                key: key,
                masterPasswordHash: request.masterPasswordHash
            )

            // If login was successful, navigate to the vault.
            coordinator.hideLoadingOverlay()
            await coordinator.handleEvent(.didCompleteAuth)
        } catch {
            await handleError(error) { await self.attemptLogin(with: request) }
        }
    }

    /// Check for a response to the login request.
    private func checkForResponse() async {
        do {
            // Get the updated request.
            guard let requestId = state.requestId else { throw AuthError.missingData }
            let request = try await services.authService.checkPendingLoginRequest(withId: requestId)

            guard request.requestApproved == true else {
                if !request.isAnswered {
                    // Keep waiting and schedule the next timer if the request hasn't been
                    // answered and approved yet.
                    setCheckTimer()
                }
                return
            }

            // Remove admin pending login request if exists
            try? await services.authService.setPendingAdminLoginRequest(nil, userId: nil)

            // Otherwise, if the request has been approved, stop the update timer
            // and attempt to authenticate.
            checkTimer?.invalidate()
            await attemptLogin(with: request)
        } catch CheckLoginRequestError.expired {
            // If the request has expired, stop the timer but don't alert the user and remain
            // on the view.
            checkTimer?.invalidate()
        } catch {
            // For any other errors, stop the timer while the alert is being shown and resume it
            // when it's dismissed.
            checkTimer?.invalidate()
            await coordinator.showErrorAlert(error: error, onDismissed: {
                self.setCheckTimer()
            })
            services.errorReporter.log(error: error)
        }
    }

    /// Generically handle an error on the view.
    private func handleError(_ error: Error, _ tryAgain: (() async -> Void)? = nil) async {
        coordinator.hideLoadingOverlay()

        // Handle a captcha or two-factor error.
        if let identityTokenError = error as? IdentityTokenRequestError {
            switch identityTokenError {
            case let .captchaRequired(token):
                await launchCaptchaFlow(with: token)
            case let .twoFactorRequired(authMethodsData, _, _, _):
                let unlockMethod: TwoFactorUnlockMethod? = if let key = approvedRequest?.key, let authRequestResponse {
                    TwoFactorUnlockMethod.loginWithDevice(
                        key: key,
                        masterPasswordHash: approvedRequest?.masterPasswordHash,
                        privateKey: authRequestResponse.privateKey
                    )
                } else {
                    nil
                }
                coordinator.navigate(to: .twoFactor(state.email, unlockMethod, authMethodsData, nil))
            case .twoFactorProvidersNotConfigured:
                services.errorReporter.log(error: error)
            case .newDeviceNotVerified:
                services.errorReporter.log(error: error)
            case .encryptionKeyMigrationRequired:
                services.errorReporter.log(error: error)
            }
            return
        }

        await coordinator.showErrorAlert(error: error, tryAgain: tryAgain)
        services.errorReporter.log(error: error)
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

    /// Set or reset the auto-check timer.
    private func setCheckTimer() {
        checkTimer?.invalidate()

        // Set the timer to auto-check for a response every four seconds.
        checkTimer = Timer.scheduledTimer(withTimeInterval: UI.duration(4), repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkForResponse()
            }
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
