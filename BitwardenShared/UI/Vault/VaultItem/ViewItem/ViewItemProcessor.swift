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
        case let .login(loginItem):
            coordinator.navigate(to: .editItem(cipher: loginItem.cipher))
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
