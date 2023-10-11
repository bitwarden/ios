import OSLog

/// The processor used to manage state and handle actions for the vault unlock screen.
///
class VaultUnlockProcessor: StateProcessor<VaultUnlockState, VaultUnlockAction, VaultUnlockEffect> {
    // MARK: Types

    typealias Services = HasAuthRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<AuthRoute>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `VaultUnlockProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute>,
        services: Services,
        state: VaultUnlockState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultUnlockEffect) async {
        switch effect {
        case .unlockVault:
            await unlockVault()
        }
    }

    override func receive(_ action: VaultUnlockAction) {
        switch action {
        case let .masterPasswordChanged(masterPassword):
            state.masterPassword = masterPassword
        case .morePressed:
            let alert = Alert(
                title: Localizations.options,
                message: nil,
                preferredStyle: .actionSheet,
                alertActions: [
                    AlertAction(title: Localizations.logOut, style: .default) { _ in
                        self.showLogoutConfirmation()
                    },
                    AlertAction(title: Localizations.cancel, style: .cancel),
                ]
            )
            coordinator.navigate(to: .alert(alert))
        case let .revealMasterPasswordFieldPressed(isMasterPasswordRevealed):
            state.isMasterPasswordRevealed = isMasterPasswordRevealed
        }
    }

    // MARK: Private

    /// Shows an alert asking the user to confirm that they want to logout.
    ///
    private func showLogoutConfirmation() {
        let alert = Alert(
            title: Localizations.logOut,
            message: Localizations.logoutConfirmation,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _ in
                    try? await self.services.authRepository.logout()
                    self.coordinator.navigate(to: .landing)
                },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ]
        )
        coordinator.navigate(to: .alert(alert))
    }

    /// Attempts to unlock the vault with the user's master password.
    ///
    private func unlockVault() async {
        do {
            try EmptyInputValidator(fieldName: Localizations.masterPassword)
                .validate(input: state.masterPassword)

            try await services.authRepository.unlockVault(password: state.masterPassword)
            coordinator.navigate(to: .complete)
        } catch let error as InputValidationError {
            coordinator.navigate(to: .alert(Alert.inputValidationAlert(error: error)))
        } catch {
            let alert = Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.invalidMasterPassword
            )
            coordinator.navigate(to: .alert(alert))
            Logger.processor.error("Error unlocking vault: \(error)")
        }
    }
}
