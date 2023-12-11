import BitwardenSdk

// MARK: - DeleteAccountProcessor

/// The processor used to manage state and handle actions for the delete account screen.
///
final class DeleteAccountProcessor: StateProcessor<DeleteAccountState, DeleteAccountAction, DeleteAccountEffect> {
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasAuthRepository
        & HasClientAuth
        & HasStateService
        & HasVaultTimeoutService

    // MARK: Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

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
        coordinator: AnyCoordinator<SettingsRoute>,
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
            await showMasterPasswordReprompt()
        }
    }

    override func receive(_ action: DeleteAccountAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        }
    }

    // MARK: Private methods

    /// Navigates to the landing screen or vault unlock screen post account deletion.
    /// If the user has another account, they're navigated to the vault unlock screen.
    /// If the user does not, they're navigated to the landing screen.
    ///
    private func navigatePostDeletion() async throws {
        try await services.stateService.logoutAccount()
        await services.vaultTimeoutService.remove(userId: nil)
        let userAccounts = try await services.stateService.getAccounts()
        coordinator.navigate(to: .didDeleteAccount(otherAccounts: userAccounts))
    }

    /// Shows the master password prompt when the user is attempting to delete their account.
    ///
    private func showMasterPasswordReprompt() async {
        coordinator.navigate(to: .alert(.masterPasswordPrompt { [weak self] passwordText in
            guard let self else { return }
            guard !passwordText.isEmpty else { return }

            do {
                try await services.authRepository.deleteAccount(passwordText: passwordText)
                try await navigatePostDeletion()
            } catch DeleteAccountRequestError.serverError(_) {
                coordinator.navigate(to: .alert(.networkResponseError(nil) {
                    try? await self.services.authRepository.deleteAccount(passwordText: passwordText)
                    try? await self.navigatePostDeletion()
                }))
            } catch {
                coordinator.navigate(to: .alert(.defaultAlert(title: Localizations.anErrorHasOccurred)))
            }
        }))
    }
}
