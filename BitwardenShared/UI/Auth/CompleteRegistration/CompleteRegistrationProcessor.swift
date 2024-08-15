import AuthenticationServices
import BitwardenSdk
import Combine
import Foundation
import OSLog

// MARK: - CompleteRegistrationError

/// Enumeration of errors that may occur when completing registration for an account.
///
enum CompleteRegistrationError: Error {
    /// The password confirmation is not correct.
    case passwordsDontMatch

    /// The password field is empty.
    case passwordEmpty

    /// The password does not meet the minimum length requirement.
    case passwordIsTooShort
}

// MARK: - CompleteRegistrationProcessor

/// The processor used to manage state and handle actions for the complete registration screen.
///
class CompleteRegistrationProcessor: StateProcessor<
    CompleteRegistrationState,
    CompleteRegistrationAction,
    CompleteRegistrationEffect
> {
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasAuthRepository
        & HasClientService
        & HasEnvironmentService
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
        case .appeared:
            await setRegion()
            await verifyUserEmail()
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
        case let .toastShown(toast):
            state.toast = toast
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

            // If unexposed and strong, complete registration
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
        defer { coordinator.hideLoadingOverlay() }

        do {
            guard !state.passwordText.isEmpty else { throw CompleteRegistrationError.passwordEmpty }

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

            _ = try await services.accountAPIService.registerFinish(
                body: RegisterFinishRequestModel(
                    captchaResponse: captchaToken,
                    email: state.userEmail,
                    emailVerificationToken: state.emailVerificationToken,
                    kdfConfig: KdfConfig(),
                    masterPasswordHash: hashedPassword,
                    masterPasswordHint: state.passwordHintText,
                    userSymmetricKey: keys.encryptedUserKey,
                    userAsymmetricKeys: KeysRequestModel(
                        encryptedPrivateKey: keys.keys.private,
                        publicKey: keys.keys.public
                    )
                )
            )

            coordinator.navigate(to: .dismissWithAction(DismissAction {
                self.coordinator.showToast(Localizations.accountSuccessfullyCreated)
            }))
        } catch let error as CompleteRegistrationError {
            showCompleteRegistrationErrorAlert(error)
        } catch {
            coordinator.showAlert(.networkResponseError(error) {
                await self.completeRegistration(captchaToken: captchaToken)
            })
        }
    }

    /// Sets the URLs to use.
    ///
    private func setRegion() async {
        guard state.region != nil,
              let urls = state.region?.defaultURLs else { return }

        await services.environmentService.setPreAuthURLs(urls: urls)
    }

    /// Shows a `CompleteRegistrationError` alert.
    ///
    /// - Parameter error: The error that occurred.
    ///
    private func showCompleteRegistrationErrorAlert(_ error: CompleteRegistrationError) {
        switch error {
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

    /// Verify users email using the provided token
    ///
    private func verifyUserEmail() async {
        // Hide the loading overlay when exiting this method, in case it hasn't been hidden yet.
        defer { coordinator.hideLoadingOverlay() }

        if state.fromEmail {
            state.toast = Toast(text: Localizations.emailVerified)
        }
    }
}
