import AuthenticationServices
import BitwardenSdk
import Combine
import Foundation
import OSLog

// MARK: - CompleteRegistrationError

/// Enumeration of errors that may occur when creating an account.
///
enum CompleteRegistrationError: Error {
    /// The terms of service and privacy policy have not been acknowledged.
    case acceptPoliciesError

    /// The password confirmation is not correct.
    case passwordsDontMatch

    /// The password field is empty.
    case passwordEmpty

    /// The password does not meet the minimum length requirement.
    case passwordIsTooShort
}

// MARK: - CompleteRegistrationProcessor

/// The processor used to manage state and handle actions for the create account screen.
///
class CompleteRegistrationProcessor: StateProcessor<
    CompleteRegistrationState,
    CompleteRegistrationAction,
    CompleteRegistrationEffect
> {
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasAuthRepository
        & HasCaptchaService
        & HasClientService
        & HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `CompleteRegistrationProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: CompleteRegistrationState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: CompleteRegistrationEffect) async {
        switch effect {
        case .completeRegistration:
            await checkPasswordAndCompleteRegistration()
        }
    }

    override func receive(_ action: CompleteRegistrationAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismissPresented)
        case let .passwordHintTextChanged(text):
            state.passwordHintText = text
        case let .passwordTextChanged(text):
            state.passwordText = text
            updatePasswordStrength()
        case let .retypePasswordTextChanged(text):
            state.retypePasswordText = text
        case let .toggleCheckDataBreaches(newValue):
            state.isCheckDataBreachesToggleOn = newValue
        case let .togglePasswordVisibility(newValue):
            state.arePasswordsVisible = newValue
        }
    }

    // MARK: Private methods

    /// Shows an alert if the user's password has been found in a data breach.
    /// Also shows an alert if it hasn't, but the password is still weak.
    ///
    /// - Parameter isWeakPassword: Whether the password is weak.
    ///
    private func checkForBreaches(isWeakPassword: Bool) async {
        do {
            coordinator.showLoadingOverlay(title: Localizations.creatingAccount)
            let breachCount = try await services.accountAPIService.checkDataBreaches(password: state.passwordText)

            // If unexposed and strong, create the account
            guard breachCount > 0 || isWeakPassword else {
                await completeRegistration()
                return
            }

            // If exposed and/or weak, show alert
            coordinator.hideLoadingOverlay()
            let alertType = Alert.PasswordStrengthAlertType(isBreached: breachCount > 0, isWeak: isWeakPassword)
            coordinator.showAlert(.passwordStrengthAlert(alertType) {
                await self.completeRegistration()
            })
        } catch {
            await completeRegistration()
            Logger.processor.error("HIBP network request failed: \(error)")
        }
    }

    /// Checks the password strength and conditionally checks the password against data breaches.
    ///
    /// An alert is shown if the password:
    /// - Is exposed and weak
    /// - is exposed and strong
    /// - is unexposed and weak
    /// - is unchecked against breaches and weak
    ///
    private func checkPasswordAndCompleteRegistration() async {
        if state.isCheckDataBreachesToggleOn {
            await checkForBreaches(isWeakPassword: state.isWeakPassword)
        } else {
            guard !state.isWeakPassword else {
                coordinator.showAlert(.passwordStrengthAlert(.weak) {
                    await self.completeRegistration()
                })
                return
            }
            await completeRegistration()
        }
    }

    /// Creates the user's account with their provided credentials.
    ///
    /// - Parameter captchaToken: The token returned when the captcha flow has completed.
    ///
    private func completeRegistration(captchaToken: String? = nil) async {
        // Hide the loading overlay when exiting this method, in case it hasn't been hidden yet.
        defer { coordinator.hideLoadingOverlay() }

        do {
            guard !state.passwordText.isEmpty else {
                throw CompleteRegistrationError.passwordEmpty
            }

            guard state.passwordText.count >= Constants.minimumPasswordCharacters else {
                throw CompleteRegistrationError.passwordIsTooShort
            }

            guard state.passwordText == state.retypePasswordText else {
                throw CompleteRegistrationError.passwordsDontMatch
            }

            coordinator.showLoadingOverlay(title: Localizations.creatingAccount)

            let kdf: Kdf = .pbkdf2(iterations: NonZeroU32(KdfConfig().kdfIterations))

            let keys = try await services.clientService.auth().makeRegisterKeys(
                email: state.userEmail,
                password: state.passwordText,
                kdf: kdf
            )

            let hashedPassword = try await services.clientService.auth().hashPassword(
                email: state.userEmail,
                password: state.passwordText,
                kdfParams: kdf,
                purpose: .serverAuthorization
            )
            // TODO: PM-5090 Add call to complete the registration and create the account /register

            _ = try await services.accountAPIService.createNewAccount(
                body: CreateAccountRequestModel(
                    captchaResponse: captchaToken,
                    email: state.userEmail,
                    kdfConfig: KdfConfig(),
                    key: keys.encryptedUserKey,
                    keys: KeysRequestModel(
                        encryptedPrivateKey: keys.keys.private,
                        publicKey: keys.keys.public
                    ),
                    masterPasswordHash: hashedPassword,
                    masterPasswordHint: state.passwordHintText
                )
            )

            coordinator.navigate(to: .login(username: state.userEmail))
        } catch let CreateAccountRequestError.captchaRequired(hCaptchaSiteCode: siteCode) {
            launchCaptchaFlow(with: siteCode)
        } catch let error as CompleteRegistrationError {
            showCompleteRegistrationErrorAlert(error)
        } catch {
            coordinator.showAlert(.networkResponseError(error) {
                await self.completeRegistration(captchaToken: captchaToken)
            })
        }
    }

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
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Shows a `CompleteRegistrationError` alert.
    ///
    /// - Parameter error: The error that occurred.
    ///
    private func showCompleteRegistrationErrorAlert(_ error: CompleteRegistrationError) {
        switch error {
        case .acceptPoliciesError:
            coordinator.showAlert(.acceptPoliciesAlert())
        case .passwordsDontMatch:
            coordinator.showAlert(.passwordsDontMatch)
        case .passwordEmpty:
            coordinator.showAlert(.validationFieldRequired(fieldName: Localizations.masterPassword))
        case .passwordIsTooShort:
            coordinator.showAlert(.passwordIsTooShort)
        }
    }

    /// Updates state's password strength score based on the user's entered password.
    ///
    private func updatePasswordStrength() {
        guard !state.passwordText.isEmpty else {
            state.passwordStrengthScore = nil
            return
        }
        Task {
            state.passwordStrengthScore = try? await services.authRepository.passwordStrength(
                email: state.userEmail,
                password: state.passwordText
            )
        }
    }
}

// MARK: - CaptchaFlowDelegate

extension CompleteRegistrationProcessor: CaptchaFlowDelegate {
    func captchaCompleted(token: String) {
        Task {
            await completeRegistration(captchaToken: token)
        }
    }

    func captchaErrored(error: Error) {
        guard (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue else { return }

        services.errorReporter.log(error: error)

        // Show the alert after a delay to ensure it doesn't try to display over the
        // closing captcha view.
        DispatchQueue.main.asyncAfter(deadline: UI.after(0.6)) {
            self.coordinator.showAlert(.networkResponseError(error))
        }
    }
}
