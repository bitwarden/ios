import BitwardenSdk

// MARK: - ViewItemProcessor

/// A processor that can process `ViewItemAction`s.
final class ViewItemProcessor: StateProcessor<ViewItemState, ViewItemAction, ViewItemEffect> {
    // MARK: Types

    typealias Services = HasVaultRepository

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
        }
    }

    override func receive(_ action: ViewItemAction) {
        if state.isMasterPasswordRequired, action.requiresMasterPasswordReprompt {
            presentMasterPasswordRepromptAlert(for: action)
        } else {
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
                // TODO: BIT-220 Navigate to the edit route
                print("edit pressed")
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
    }

    // MARK: Private Methods

    /// Presents the master password reprompt alert for the specified action. This method will
    /// process the action once the master password has been verified.
    ///
    /// - Parameter action: The action to process once the password has been verfied.
    ///
    private func presentMasterPasswordRepromptAlert(for action: ViewItemAction) {
        let alert = Alert.masterPasswordPrompt { [weak self] _ in
            guard let self else { return }

            // TODO: BIT-1208 Validate the master password
            state.isMasterPasswordRequired = false
            receive(action)
        }
        coordinator.navigate(to: .alert(alert))
    }
}
