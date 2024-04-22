import BitwardenSdk

// MARK: - DeleteAccountProcessor

/// The processor used to manage state and handle actions for the delete account screen.
///
final class DeleteAccountProcessor: StateProcessor<DeleteAccountState, DeleteAccountAction, DeleteAccountEffect> {
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasAuthRepository
        & HasErrorReporter
        & HasStateService

    // MARK: Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Initializes a `DeleteAccountProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: DeleteAccountState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: DeleteAccountEffect) async {
        switch effect {
        case .deleteAccount:
            await showAccountVerification()
        }
    }

    override func receive(_ action: DeleteAccountAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        }
    }

    // MARK: Private methods

    /// Deletes the user's account.
    ///
    /// - Parameters:
    ///   - otp: The user's one-time password, if they don't have a master password.
    ///   - passwordText: The user's password.
    ///
    private func deleteAccount(otp: String?, passwordText: String?) async {
        coordinator.showLoadingOverlay(title: Localizations.deletingYourAccount)
        defer {
            coordinator.hideLoadingOverlay()
        }

        do {
            try await services.authRepository.deleteAccount(otp: otp, passwordText: passwordText)
            navigatePostDeletion()
        } catch {
            coordinator.showAlert(.networkResponseError(error) {
                await self.deleteAccount(otp: otp, passwordText: passwordText)
            })
        }
    }

    /// Navigates to the landing screen or vault unlock screen post account deletion.
    /// If the user has another account, they're navigated to the vault unlock screen.
    /// If the user does not, they're navigated to the landing screen.
    ///
    private func navigatePostDeletion() {
        Task {
            await coordinator.handleEvent(.didDeleteAccount)
        }
    }

    /// Shows the master password prompt when the user is attempting to delete their account.
    ///
    private func showMasterPasswordReprompt() async {
        coordinator.showAlert(.masterPasswordPrompt { [weak self] passwordText in
            await self?.deleteAccount(otp: nil, passwordText: passwordText)
        })
    }

    /// Shows an alert for account verification. This will either require the user to enter their
    /// master password or a one-time password that was emailed to them depending on if they have a
    /// master password or not.
    ///
    private func showAccountVerification() async {
        do {
            if try await services.authRepository.hasMasterPassword() {
                coordinator.showAlert(.masterPasswordPrompt { passwordText in
                    await self.deleteAccount(otp: nil, passwordText: passwordText)
                })
            } else {
                coordinator.showLoadingOverlay(title: Localizations.sendingCode)
                defer {
                    coordinator.hideLoadingOverlay()
                }

                try await services.authRepository.requestOtp()

                coordinator.showAlert(.verificationCodePrompt { otp in
                    await self.deleteAccount(otp: otp, passwordText: nil)
                })
            }
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }
}
