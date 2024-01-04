import Foundation

// MARK: - SingleSignOnFlowDelegate

/// An object that is signaled when specific circumstances in the single sign on flow have been encountered.
///
protocol SingleSignOnFlowDelegate: AnyObject {
    /// Called when the single sign on flow has been completed successfully.
    ///
    /// - Parameter code: The code that was returned by the single sign on web auth process.
    ///
    func singleSignOnCompleted(code: String)

    /// Called when the single sign on flow encounters an error.
    ///
    /// - Parameter error: The error that was encountered.
    ///
    func singleSignOnErrored(error: Error)
}

// MARK: - SingleSignOnProcessor

/// The processor used to manage state and handle actions for the `SingleSignOnView`.
///
final class SingleSignOnProcessor: StateProcessor<SingleSignOnState, SingleSignOnAction, SingleSignOnEffect> {
    // MARK: Types

    typealias Services = HasAuthService
        & HasErrorReporter
        & HasStateService

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `SingleSignOnProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute>,
        services: Services,
        state: SingleSignOnState
    ) {
        self.coordinator = coordinator
        self.services = services

        // Set the initial value of the organization identifier, if applicable.
        var state = state
        state.identifierText = self.services.stateService.rememberedOrgIdentifier ?? ""

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SingleSignOnEffect) async {
        switch effect {
        case .loginTapped:
            await handleLoginTapped()
        }
    }

    override func receive(_ action: SingleSignOnAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .identifierTextChanged(newValue):
            state.identifierText = newValue
        }
    }

    // MARK: Private Methods

    /// Generically handle an error on the view.
    private func handleError(_ error: Error, _ tryAgain: (() async -> Void)? = nil) {
        coordinator.hideLoadingOverlay()
        coordinator.showAlert(.networkResponseError(error, tryAgain))
        services.errorReporter.log(error: error)
    }

    /// Handle attempting to login.
    private func handleLoginTapped() async {
        do {
            try EmptyInputValidator(fieldName: Localizations.orgIdentifier)
                .validate(input: state.identifierText)
            coordinator.showLoadingOverlay(title: Localizations.loggingIn)

            // Generate the URL and initiate a web auth view with it.
            let result = try await services.authService.generateSingleSignOnUrl(from: state.identifierText)
            coordinator.navigate(
                to: .singleSignOn(
                    callbackUrlScheme: services.authService.callbackUrlScheme,
                    state: result.state,
                    url: result.url
                ),
                context: self
            )
        } catch let error as InputValidationError {
            coordinator.hideLoadingOverlay()
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
        } catch {
            handleError(error) { await self.handleLoginTapped() }
        }
    }
}

// MARK: - SingleSignOnFlowDelegate

extension SingleSignOnProcessor: SingleSignOnFlowDelegate {
    func singleSignOnCompleted(code: String) {
        // Complete the login process using the single sign on information.
        Task {
            do {
                // Use the code to authenticate the user with Bitwarden.
                let account = try await self.services.authService.loginWithSingleSignOn(code: code)

                // Remember the organization identifier after successfully logging on.
                services.stateService.rememberedOrgIdentifier = state.identifierText

                // Dismiss the loading overlay.
                coordinator.hideLoadingOverlay()

                // Show the appropriate view and dismiss this sheet.
                if let account {
                    coordinator.navigate(to: .vaultUnlock(account, animated: false))
                } else {
                    coordinator.navigate(to: .complete)
                }
                coordinator.navigate(to: .dismiss)
            } catch {
                // The delay is necessary in order to ensure the alert displays over the WebAuth view.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.handleError(error)
                }
            }
        }
    }

    func singleSignOnErrored(error: Error) {
        // The delay is necessary in order to ensure the alert displays over the WebAuth view.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.handleError(error)
        }
    }
}
