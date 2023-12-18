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

    /// The password was found in data breaches.
    case passwordBreachesFound

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
        & HasClientAuth
        & HasCaptchaService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

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
        coordinator: AnyCoordinator<AuthRoute>,
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
            await checkForBreachesAndCreateAccount()
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

    /// Checks if the user's entered password has been found in a data breach.
    /// If it has, an alert will be presented. If not, the `CreateAccountRequest`
    /// will be made.
    ///
    private func checkForBreachesAndCreateAccount() async {
        guard state.isCheckDataBreachesToggleOn else {
            await createAccount()
            return
        }

        do {
            let breachCount = try await services.accountAPIService.checkDataBreaches(password: state.passwordText)
            guard breachCount == 0 else {
                let alert = Alert.breachesAlert {
                    await self.createAccount()
                }
                coordinator.navigate(to: .alert(alert))
                return
            }
        } catch {
            Logger.processor.error("HIBP network request failed: \(error)")
        }

        await createAccount()
    }

    /// Creates the user's account with their provided credentials.
    ///
    /// - Parameter captchaToken: The token returned when the captcha flow has completed.
    ///
    private func createAccount(captchaToken: String? = nil) async {
        // swiftlint:disable:previous function_body_length cyclomatic_complexity
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

            let kdf: Kdf = .pbkdf2(iterations: NonZeroU32(KdfConfig().kdfIterations))

            let keys = try await services.clientAuth.makeRegisterKeys(
                email: email,
                password: state.passwordText,
                kdf: kdf
            )

            let hashedPassword = try await services.clientAuth.hashPassword(
                email: email,
                password: state.passwordText,
                kdfParams: kdf
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

            coordinator.navigate(to: .login(
                username: email,
                region: LoginState().region,
                isLoginWithDeviceVisible: LoginState().isLoginWithDeviceVisible
            ))
        } catch CreateAccountError.acceptPoliciesError {
            coordinator.navigate(to: .alert(.acceptPoliciesAlert()))
        } catch CreateAccountError.emailEmpty {
            coordinator.navigate(to: .alert(.validationFieldRequired(fieldName: Localizations.email)))
        } catch CreateAccountError.invalidEmail {
            coordinator.navigate(to: .alert(.invalidEmail))
        } catch CreateAccountError.passwordsDontMatch {
            coordinator.navigate(to: .alert(.passwordsDontMatch))
        } catch CreateAccountError.passwordEmpty {
            coordinator.navigate(to: .alert(.validationFieldRequired(fieldName: Localizations.masterPassword)))
        } catch CreateAccountError.passwordIsTooShort {
            coordinator.navigate(to: .alert(.passwordIsTooShort))
        } catch let CreateAccountRequestError.captchaRequired(hCaptchaSiteCode: siteCode) {
            launchCaptchaFlow(with: siteCode)
        } catch let CreateAccountRequestError.serverError(errorResponse) {
            coordinator.navigate(to: .alert(.serverError(errorResponse.singleMessage())))
        } catch {
            coordinator.navigate(to: .alert(.networkResponseError(error) {
                await self.createAccount(captchaToken: captchaToken)
            }))
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
            // TODO: BIT-887 Show alert for when hCaptcha fails
            print(error)
        }
    }

    /// Updates state's password strength score based on the user's entered password.
    ///
    private func updatePasswordStrength() {
        // TODO: BIT-694 Use the SDK to calculate password strength
        let score: UInt8?
        switch state.passwordText.count {
        case 1 ..< 4: score = 0
        case 4 ..< 7: score = 1
        case 7 ..< 9: score = 2
        case 9 ..< 12: score = 3
        case 12 ... Int.max: score = 4
        default: score = nil
        }
        state.passwordStrengthScore = score
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
        // TODO: BIT-681
        print(error)
    }
}
