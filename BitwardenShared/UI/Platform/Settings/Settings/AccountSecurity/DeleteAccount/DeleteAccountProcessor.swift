import BitwardenSdk

// MARK: - DeleteAccountProcessor

/// The processor used to manage state and handle actions for the delete account screen.
///
final class DeleteAccountProcessor: StateProcessor<DeleteAccountState, DeleteAccountAction, DeleteAccountEffect> {
    // MARK: Types

    typealias Services = HasAccountAPIService
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

    /// Makes the API call that deletes the user's account.
    ///
    /// - Parameter passwordText: The password entered by the user.
    ///
    private func deleteAccount(passwordText: String) async throws {
        let hashedPassword = try await hashPassword(passwordText: passwordText)

        _ = try await services.accountAPIService.deleteAccount(
            body: DeleteAccountRequestModel(masterPasswordHash: hashedPassword)
        )

        try await navigatePostDeletion()
    }

    /// Creates a hash value for the user's master password.
    ///
    /// - Parameter passwordText: The user's entered password.
    /// - Returns: A hash value of the password text.
    ///
    private func hashPassword(passwordText: String) async throws -> String {
        let email = try await services.stateService.getActiveAccount().profile.email
        let kdf: Kdf = .pbkdf2(iterations: NonZeroU32(KdfConfig().kdfIterations))

        let hashedPassword = try await services.clientAuth.hashPassword(
            email: email,
            password: passwordText,
            kdfParams: kdf
        )

        return hashedPassword
    }

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
            Task {
                guard let self else { return }
                guard !passwordText.isEmpty else { return }

                do {
                    try await self.deleteAccount(passwordText: passwordText)
                } catch DeleteAccountRequestError.serverError(_) {
                    self.coordinator.navigate(to: .alert(.genericRequestError()))
                }
            }
        }))
    }
}
