import AuthenticationServices
import BitwardenSdk
import Combine
import Foundation
import OSLog

// MARK: - CreateAccountError

/// Enumeration of errors that may occur when creating an account.
///
enum CreateAccountError: Error {
    /// The terms of service and privacy policy have not been acknowledged.
    case acceptPoliciesError

    /// The email field is empty.
    case emailEmpty

    /// The email is invalid.
    case invalidEmail

    /// The password confirmation is not correct.
    case passwordsDontMatch

    /// The password field is empty.
    case passwordEmpty

    /// The password does not meet the minimum length requirement.
    case passwordIsTooShort
}

// MARK: - CreateAccountProcessor

/// The processor used to manage state and handle actions for the create account screen.
///
class CreateAccountProcessor: StateProcessor<CreateAccountState, CreateAccountAction, CreateAccountEffect> {
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasAuthRepository
        & HasCaptchaService
        & HasClientAuth
        & HasErrorReporter

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `CreateAccountProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: CreateAccountState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: CreateAccountEffect) async {
        switch effect {
        case .createAccount:
            await checkPasswordAndCreateAccount()
        }
    }

    override func receive(_ action: CreateAccountAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .emailTextChanged(text):
            state.emailText = text
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
        case let .toggleTermsAndPrivacy(newValue):
            state.isTermsAndPrivacyToggleOn = newValue
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
                await createAccount()
                return
            }

            // If exposed and/or weak, show alert
            coordinator.hideLoadingOverlay()
            let alertType = Alert.PasswordStrengthAlertType(isBreached: breachCount > 0, isWeak: isWeakPassword)
            coordinator.showAlert(.passwordStrengthAlert(alertType) {
                await self.createAccount()
            })
        } catch {
            await createAccount()
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
    private func checkPasswordAndCreateAccount() async {
        if state.isCheckDataBreachesToggleOn {
            await checkForBreaches(isWeakPassword: state.isWeakPassword)
        } else {
            guard !state.isWeakPassword else {
                coordinator.showAlert(.passwordStrengthAlert(.weak) {
                    await self.createAccount()
                })
                return
            }
            await createAccount()
        }
    }

    /// Creates the user's account with their provided credentials.
    ///
    /// - Parameter captchaToken: The token returned when the captcha flow has completed.
    ///
    private func createAccount(captchaToken: String? = nil) async {
        // swiftlint:disable:previous function_body_length

        // Hide the loading overlay when exiting this method, in case it hasn't been hidden yet.
        defer { coordinator.hideLoadingOverlay() }

        do {
            let email = state.emailText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !email.isEmpty else {
                throw CreateAccountError.emailEmpty
            }

            guard email.isValidEmail else {
                throw CreateAccountError.invalidEmail
            }

            guard !state.passwordText.isEmpty else {
                throw CreateAccountError.passwordEmpty
            }

            guard state.passwordText.count >= Constants.minimumPasswordCharacters else {
                throw CreateAccountError.passwordIsTooShort
            }

            guard state.passwordText == state.retypePasswordText else {
                throw CreateAccountError.passwordsDontMatch
            }

            guard state.isTermsAndPrivacyToggleOn else {
                throw CreateAccountError.acceptPoliciesError
            }

            coordinator.showLoadingOverlay(title: Localizations.creatingAccount)

            let kdf: Kdf = .pbkdf2(iterations: NonZeroU32(KdfConfig().kdfIterations))

            let keys = try await services.clientAuth.makeRegisterKeys(
                email: email,
                password: state.passwordText,
                kdf: kdf
            )

            let hashedPassword = try await services.clientAuth.hashPassword(
                email: email,
                password: state.passwordText,
                kdfParams: kdf,
                purpose: .serverAuthorization
            )

            _ = try await services.accountAPIService.createNewAccount(
                body: CreateAccountRequestModel(
                    captchaResponse: captchaToken,
                    email: email,
                    kdfConfig: KdfConfig(),
                    key: keys.encryptedUserKey,
                    keys: KeysRequestModel(
                        publicKey: keys.keys.public,
                        encryptedPrivateKey: keys.keys.private
                    ),
                    masterPasswordHash: hashedPassword,
                    masterPasswordHint: state.passwordHintText
                )
            )
            coordinator.navigate(to: .login(username: email))
        } catch let CreateAccountRequestError.captchaRequired(hCaptchaSiteCode: siteCode) {
            launchCaptchaFlow(with: siteCode)
        } catch let error as CreateAccountError {
            showCreateAccountErrorAlert(error)
        } catch {
            coordinator.showAlert(.networkResponseError(error) {
                await self.createAccount(captchaToken: captchaToken)
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

    /// Shows a `CreateAccountError` alert.
    ///
    /// - Parameter error: The error that occurred.
    ///
    private func showCreateAccountErrorAlert(_ error: CreateAccountError) {
        switch error {
        case .acceptPoliciesError:
            coordinator.showAlert(.acceptPoliciesAlert())
        case .emailEmpty:
            coordinator.showAlert(.validationFieldRequired(fieldName: Localizations.email))
        case .invalidEmail:
            coordinator.showAlert(.invalidEmail)
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
            state.passwordStrengthScore = await services.authRepository.passwordStrength(
                email: state.emailText,
                password: state.passwordText
            )
        }
    }
}

// MARK: - CaptchaFlowDelegate

extension CreateAccountProcessor: CaptchaFlowDelegate {
    func captchaCompleted(token: String) {
        Task {
            await createAccount(captchaToken: token)
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
