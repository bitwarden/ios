// MARK: - AddItemProcessor

/// The processor used to manage state and handle actions for the add item screen.
///
final class AddItemProcessor: StateProcessor<AddItemState, AddItemAction, AddItemEffect> {
    // MARK: Types

    typealias Services = HasCameraAuthorizationService
        & HasVaultRepository

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultRoute>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `AddItemProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state for the processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute>,
        services: Services,
        state: AddItemState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AddItemEffect) async {
        switch effect {
        case .checkPasswordPressed:
            await checkPassword()
        case .savePressed:
            await saveItem()
        case .setupTotpPressed:
            await setupTotp()
        }
    }

    override func receive(_ action: AddItemAction) {
        switch action {
        case .dismissPressed:
            coordinator.navigate(to: .dismiss)
        case let .favoriteChanged(newValue):
            state.isFavoriteOn = newValue
        case let .folderChanged(newValue):
            state.folder = newValue
        case .generatePasswordPressed:
            coordinator.navigate(to: .generator)
        case .generateUsernamePressed:
            coordinator.navigate(to: .generator)
        case let .masterPasswordRePromptChanged(newValue):
            state.isMasterPasswordRePromptOn = newValue
        case let .nameChanged(newValue):
            state.name = newValue
        case .newCustomFieldPressed:
            presentCustomFieldAlert()
        case .newUriPressed:
            // TODO: BIT-901 Add a new blank URI field
            break
        case let .notesChanged(newValue):
            state.notes = newValue
        case let .ownerChanged(newValue):
            state.owner = newValue
        case let .passwordChanged(newValue):
            state.password = newValue
        case let .togglePasswordVisibilityChanged(newValue):
            state.isPasswordVisible = newValue
        case let .typeChanged(newValue):
            state.type = newValue
        case let .uriChanged(newValue):
            state.uri = newValue
        case .uriSettingsPressed:
            presentUriSettingsAlert()
        case let .usernameChanged(newValue):
            state.username = newValue
        }
    }

    // MARK: Private Methods

    /// Checks the password currently stored in `state`.
    ///
    private func checkPassword() async {
        coordinator.showLoadingOverlay(title: Localizations.checkingPassword)
        defer { coordinator.hideLoadingOverlay() }

        do {
            // TODO: BIT-369 Use the api to check the password
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let alert = Alert(
                title: Localizations.passwordExposed(9_659_365),
                message: nil,
                alertActions: [
                    AlertAction(
                        title: Localizations.ok,
                        style: .default
                    ),
                ]
            )
            coordinator.navigate(to: .alert(alert))
        } catch {
            print(error)
        }
    }

    /// Builds an alert for creating a new custom field and then routes the coordinator
    /// to the `.alert` route.
    ///
    private func presentCustomFieldAlert() {
        // TODO: BIT-368 Navigate to an `.alert` route with the custom field alert
    }

    /// Builds an alert for changing the settings for a uri item and then routes
    /// the coordinator to the `.alert` route.
    ///
    private func presentUriSettingsAlert() {
        // TODO: BIT-901 Navigate to an `.alert` route with the uri settings alert
    }

    /// Saves the item currently stored in `state`.
    ///
    private func saveItem() async {
        coordinator.showLoadingOverlay(title: Localizations.saving)
        defer { coordinator.hideLoadingOverlay() }

        do {
            try await services.vaultRepository.addCipher(state.cipher())
            coordinator.hideLoadingOverlay()
            coordinator.navigate(to: .dismiss)
        } catch {
            print(error)
        }
    }

    /// Kicks off the TOTP setup flow.
    ///
    private func setupTotp() async {
        let status = await services.cameraAuthorizationService.checkStatusOrRequestCameraAuthorization()
        if status == .authorized {
            coordinator.navigate(to: .setupTotpCamera)
        } else {
            coordinator.navigate(to: .setupTotpManual)
        }
    }
}
