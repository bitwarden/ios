import AuthenticationServices
import BitwardenSdk
import Combine
import Foundation
import OSLog

// MARK: - StartRegistrationDelegate

/// A delegate of `StartRegistrationProcessor` that is notified when the user changes region.
///
protocol StartRegistrationDelegate: AnyObject {
    /// Called when the user changes regions.
    ///
    func didChangeRegion() async
}

// MARK: - StartRegistrationError

/// Enumeration of errors that may occur when start registration.
///
enum StartRegistrationError: Error {
    /// The terms of service and privacy policy have not been acknowledged.
    case acceptPoliciesError

    /// The email field is empty.
    case emailEmpty

    /// The email is invalid.
    case invalidEmail
}

// MARK: - StartRegistrationProcessor

/// The processor used to manage state and handle actions for the start registration screen.
///
class StartRegistrationProcessor: StateProcessor<
    StartRegistrationState,
    StartRegistrationAction,
    StartRegistrationEffect
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

    /// The delegate for the processor that is notified when the user closes the registration view.
    private weak var delegate: StartRegistrationDelegate?

    /// Helper class with region specific functions
    var regionHelper: RegionHelper?

    // MARK: Initialization

    /// Creates a new `StartRegistrationProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        delegate: StartRegistrationDelegate?,
        services: Services,
        state: StartRegistrationState
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: StartRegistrationEffect) async {
        switch effect {
        case .appeared:
            await regionHelper?.loadRegion()
            state.isReceiveMarketingToggleOn = state.region == .unitedStates
        case .regionTapped:
            await regionHelper?.presentRegionSelectorAlert(
                title: Localizations.creatingOn,
                currentRegion: state.region
            )
        case .startRegistration:
            await startRegistration()
        }
    }

    override func receive(_ action: StartRegistrationAction) {
        switch action {
        case let .emailTextChanged(text):
            state.emailText = text
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .nameTextChanged(text):
            state.nameText = text
        case let .toggleReceiveMarketing(newValue):
            state.isReceiveMarketingToggleOn = newValue
        case let .toastShown(toast):
            state.toast = toast
        }
    }

    // MARK: Private methods

    /// Initiates the first step of the registration.
    ///
    private func startRegistration() async {
        // Hide the loading overlay when exiting this method, in case it hasn't been hidden yet.
        defer { coordinator.hideLoadingOverlay() }

        do {
            let email = state.emailText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let name = state.nameText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !email.isEmpty else {
                throw StartRegistrationError.emailEmpty
            }

            guard email.isValidEmail else {
                throw StartRegistrationError.invalidEmail
            }

            coordinator.showLoadingOverlay(title: Localizations.creatingAccount)

            let result = try await services.accountAPIService.startRegistration(
                requestModel: StartRegistrationRequestModel(
                    email: email,
                    name: name,
                    receiveMarketingEmails: state.isReceiveMarketingToggleOn
                )
            )

            if let token = result.token,
               !token.isEmpty {
                coordinator.navigate(to: .completeRegistration(
                    emailVerificationToken: token,
                    userEmail: state.emailText
                ))
            } else {
                coordinator.navigate(to: .checkEmail(email: state.emailText))
            }
        } catch let error as StartRegistrationError {
            showStartRegistrationErrorAlert(error)
        } catch {
            coordinator.showAlert(.networkResponseError(error) {
                await self.startRegistration()
            })
        }
    }

    /// Shows a `StartRegistrationError` alert.
    ///
    /// - Parameter error: The error that occurred.
    ///
    private func showStartRegistrationErrorAlert(_ error: StartRegistrationError) {
        switch error {
        case .acceptPoliciesError:
            coordinator.showAlert(.acceptPoliciesAlert())
        case .emailEmpty:
            coordinator.showAlert(.validationFieldRequired(fieldName: Localizations.email))
        case .invalidEmail:
            coordinator.showAlert(.invalidEmail)
        }
    }
}

// MARK: - SelfHostedProcessorDelegate

extension StartRegistrationProcessor: SelfHostedProcessorDelegate {
    func didSaveEnvironment(urls: EnvironmentUrlData) async {
        await setRegion(.selfHosted, urls)
        state.toast = Toast(text: Localizations.environmentSaved)
    }
}

// MARK: - RegionDelegate

extension StartRegistrationProcessor: RegionDelegate {
    /// Sets the region and the URLs to use.
    ///
    /// - Parameters:
    ///   - region: The region to use.
    ///   - urls: The URLs that the app should use for the region.
    ///
    func setRegion(_ region: RegionType, _ urls: EnvironmentUrlData) async {
        guard !urls.isEmpty else { return }
        await services.environmentService.setPreAuthURLs(urls: urls)
        state.region = region
        state.showReceiveMarketingToggle = state.region != .selfHosted
        await delegate?.didChangeRegion()
    }
}
