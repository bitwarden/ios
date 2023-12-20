import BitwardenSdk

// MARK: - ViewItemProcessor

/// A processor that can process `ViewItemAction`s.
final class ViewItemProcessor: StateProcessor<ViewItemState, ViewItemAction, ViewItemEffect> {
    // MARK: Types

    typealias Services = HasVaultRepository
        & HasErrorReporter

    // MARK: Subtypes

    /// An error case for ViewItemAction errors.
    enum ActionError: Error, Equatable {
        /// An action that requires data has been performed while loading.
        case dataNotLoaded(String)
        /// A password visibility toggle occured when not possible.
        case nonLoginPasswordToggle(String)
    }

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
                guard var newState = ViewItemState(cipherView: value) else { continue }
                newState.hasVerifiedMasterPassword = state.hasVerifiedMasterPassword
                state = newState
            }
        }
    }

    override func receive(_ action: ViewItemAction) {
        guard !state.isMasterPasswordRequired || !action.requiresMasterPasswordReprompt else {
            presentMasterPasswordRepromptAlert(for: action)
            return
        }
        switch action {
        case .checkPasswordPressed:
            // TODO: BIT-1130 Check password
            print("check password")
        case let .copyPressed(value):
            // TODO: BIT-1121 Copy value to clipboard
            print("copy: \(value)")
        case let .customFieldVisibilityPressed(customFieldState):
            guard case var .data(cipherState) = state.loadingState else {
                services.errorReporter.log(
                    error: ActionError.dataNotLoaded("Cannot toggle password for non-loaded item.")
                )
                return
            }
            cipherState.togglePasswordVisibility(for: customFieldState)
            state.loadingState = .data(cipherState)
        case .dismissPressed:
            coordinator.navigate(to: .dismiss)
        case .editPressed:
            editItem()
        case .morePressed:
            // TODO: BIT-1131 Open item menu
            print("more pressed")
        case .passwordVisibilityPressed:
            guard case var .data(cipherState) = state.loadingState else {
                services.errorReporter.log(
                    error: ActionError.dataNotLoaded("Cannot toggle password for non-loaded item.")
                )
                return
            }
            guard case .login = cipherState.type else {
                services.errorReporter.log(
                    error: ActionError.nonLoginPasswordToggle("Cannot toggle password for non-login item.")
                )
                return
            }
            cipherState.loginState.isPasswordVisible.toggle()
            state.loadingState = .data(cipherState)
        }
    }

    // MARK: Private Methods

    /// Triggers the edit state for the item currently stored in `state`.
    ///
    private func editItem() {
        guard case let .data(cipherState) = state.loadingState,
              case let .existing(cipher) = cipherState.configuration else {
            return
        }
        coordinator.navigate(to: .editItem(cipher: cipher))
    }

    /// Presents the master password reprompt alert for the specified action. This method will
    /// process the action once the master password has been verified.
    ///
    /// - Parameter action: The action to process once the password has been verfied.
    ///
    private func presentMasterPasswordRepromptAlert(for action: ViewItemAction) {
        let alert = Alert.masterPasswordPrompt { [weak self] password in
            guard let self else { return }

            do {
                let isValid = try await services.vaultRepository.validatePassword(password)
                guard isValid else {
                    coordinator.navigate(to: .alert(Alert.defaultAlert(title: Localizations.invalidMasterPassword)))
                    return
                }
                state.hasVerifiedMasterPassword = true
                receive(action)
            } catch {
                services.errorReporter.log(error: error)
            }
        }
        coordinator.navigate(to: .alert(alert))
    }
}
