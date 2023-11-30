import BitwardenSdk

// MARK: - ViewItemProcessor

/// A processor that can process `ViewItemAction`s.
final class ViewItemProcessor: StateProcessor<ViewItemState, ViewItemAction, ViewItemEffect> {
    // MARK: Types

    typealias Services = HasCameraAuthorizationService
        & HasVaultRepository
        & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` for this processor.
    private let coordinator: any Coordinator<VaultItemRoute>

    /// The ID of the item being viewed.
    private let itemId: String

    /// The services used by this processor.
    private let services: Services

    // MARK: Intialization

    /// Creates a new `ViewItemProcessor`.
    ///
    /// - Parameters:
    ///   - coordiantor: The `Coordinator` for this processor.
    ///   - itemId: The id of the item that is being viewed.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: any Coordinator<VaultItemRoute>,
        itemId: String,
        services: Services,
        state: ViewItemState
    ) {
        self.coordinator = coordinator
        self.itemId = itemId
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ViewItemEffect) async {
        switch effect {
        case .appeared:
            for await value in services.vaultRepository.cipherDetailsPublisher(id: itemId) {
                guard let newState = ViewItemState(cipherView: value) else { continue }
                state = newState
            }
        case .savePressed:
            await saveItem()
        case .checkPasswordPressed:
            await checkPassword()
        case .setupTotpPressed:
            await setupTotp()
        }
    }

    override func receive(_ action: ViewItemAction) {
        switch action {
        case .checkPasswordPressed:
            // TODO: BIT-1130 Check password
            print("check password")
        case let .copyPressed(value):
            // TODO: BIT-1121 Copy value to clipboard
            print("copy: \(value)")
        case let .customFieldVisibilityPressed(customFieldState):
            switch state.loadingState {
            case var .data(.login(loginState)):
                loginState.togglePasswordVisibility(for: customFieldState)
                state.loadingState = .data(.login(loginState))
            default:
                assertionFailure("Cannot toggle password for non-login item.")
            }
        case .dismissPressed:
            coordinator.navigate(to: .dismiss)
        case .editPressed:
            editItem()
        case .morePressed:
            // TODO: BIT-1131 Open item menu
            print("more pressed")
        case .passwordVisibilityPressed:
            switch state.loadingState {
            case var .data(.login(loginState)):
                loginState.isPasswordVisible.toggle()
                state.loadingState = .data(.login(loginState))
            default:
                assertionFailure("Cannot toggle password for non-login item.")
            }
        case let .editAction(editAction):
            handleEditAction(editAction)
        }
    }

    // MARK: Private Methods

    /// Checks the password currently stored in `state`.
    ///
    private func checkPassword() async {
        coordinator.showLoadingOverlay(.init(title: Localizations.checkingPassword))
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

    /// Triggers the edit state for the item currently stored in `state`.
    ///
    private func editItem() {
        guard case let .data(itemTypeState) = state.loadingState else { return }
        switch itemTypeState {
        case var .login(loginItem):
            guard case .view = loginItem.editState else { return }
            loginItem.editState = .edit(
                .init(
                    isPasswordVisible: loginItem.isPasswordVisible,
                    properties: loginItem.properties
                )
            )
            state.loadingState = .data(.login(loginItem))
        }
    }

    /// Handles edit actions.
    ///
    /// - Parameter editAction: The action to be handled.
    ///
    private func handleEditAction(_ editAction: EditLoginItemAction) {
        guard case let .data(data) = state.loadingState else { return }
        switch data {
        case var .login(loginState):
            if case var .edit(editState) = loginState.editState {
                switch editAction {
                case let .favoriteChanged(isOn):
                    editState.properties.isFavoriteOn = isOn
                case let .masterPasswordRePromptChanged(isOn):
                    editState.properties.isMasterPasswordRePromptOn = isOn
                case let .nameChanged(name):
                    editState.properties.name = name
                case .newUriPressed:
                    // TODO: BIT-901 Add a new blank URI field
                    break
                case let .notesChanged(notes):
                    editState.properties.notes = notes
                case let .passwordChanged(password):
                    editState.properties.password = password
                case let .togglePasswordVisibilityChanged(isOn):
                    editState.isPasswordVisible = isOn
                case let .uriChanged(uri):
                    editState.properties.uris = [
                        .init(uri: uri, match: .none),
                    ]
                case .uriSettingsPressed:
                    // TODO: BIT-901 Navigate to an `.alert` route with the uri settings alert
                    break
                case let .usernameChanged(username):
                    editState.properties.username = username
                }
                loginState.editState = .edit(editState)
                state.loadingState = .data(.login(loginState))
            }
        }
    }

    /// Saves the item currently stored in `state`.
    ///
    private func saveItem() async {
        guard case let .data(itemTypeState) = state.loadingState else {
            return
        }
        switch itemTypeState {
        case var .login(loginItem):
            guard loginItem.hasEdits else {
                loginItem.editState = .view
                state.loadingState = .data(.login(loginItem))
                return
            }
            coordinator.showLoadingOverlay(.init(title: Localizations.saving))
            defer { coordinator.hideLoadingOverlay() }
            do {
                try await services.vaultRepository.updateCipher(loginItem.cipher.updatedView(with: loginItem.editState))
                loginItem.editState = .view
                state.loadingState = .data(.login(loginItem))
                coordinator.hideLoadingOverlay()
            } catch {
                services.errorReporter.log(error: error)
            }
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
