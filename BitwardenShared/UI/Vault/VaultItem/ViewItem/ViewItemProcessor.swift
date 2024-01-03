import BitwardenSdk

// MARK: - ViewItemProcessor

/// A processor that can process `ViewItemAction`s.
final class ViewItemProcessor: StateProcessor<ViewItemState, ViewItemAction, ViewItemEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasPasteboardService
        & HasVaultRepository

    // MARK: Subtypes

    /// An error case for ViewItemAction errors.
    enum ActionError: Error, Equatable {
        /// An action that requires data has been performed while loading.
        case dataNotLoaded(String)

        /// An error for card action handling
        case nonCardTypeToggle(String)

        /// A password visibility toggle occured when not possible.
        case nonLoginPasswordToggle(String)
    }

    // MARK: Private Properties

    /// The `Coordinator` for this processor.
    private let coordinator: any Coordinator<VaultItemRoute>

    /// The delegate that is notified when delete cipher item have occurred.
    private weak var delegate: CipherItemOperationDelegate?

    /// The ID of the item being viewed.
    private let itemId: String

    /// The services used by this processor.
    private let services: Services

    // MARK: Intialization

    /// Creates a new `ViewItemProcessor`.
    ///
    /// - Parameters:
    ///   - coordiantor: The `Coordinator` for this processor.
    ///   - delegate: The delegate that is notified when add/edit/delete cipher item have occurred.
    ///   - itemId: The id of the item that is being viewed.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: any Coordinator<VaultItemRoute>,
        delegate: CipherItemOperationDelegate?,
        itemId: String,
        services: Services,
        state: ViewItemState
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.itemId = itemId
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ViewItemEffect) async {
        switch effect {
        case .appeared:
            for await value in services.vaultRepository.cipherDetailsPublisher(id: itemId) {
                let hasPremium = await (try? services.vaultRepository.doesActiveAccountHavePremium())
                    ?? false
                guard var newState = ViewItemState(cipherView: value, hasPremium: hasPremium) else { continue }
                newState.hasVerifiedMasterPassword = state.hasVerifiedMasterPassword
                state = newState
            }
        case .deletePressed:
            await showDeleteConfirmation()
        }
    }

    override func receive(_ action: ViewItemAction) {
        guard !state.isMasterPasswordRequired || !action.requiresMasterPasswordReprompt else {
            presentMasterPasswordRepromptAlert(for: action)
            return
        }
        switch action {
        case let .cardItemAction(cardAction):
            handleCardAction(cardAction)
        case .checkPasswordPressed:
            // TODO: BIT-1130 Check password
            print("check password")
        case let .copyPressed(value):
            copyValue(value)
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
            coordinator.navigate(to: .dismiss())
        case .editPressed:
            editItem()
        case let .morePressed(menuAction):
            switch menuAction {
            case .attachments:
                // TODO: BIT-364
                print("attachments")
            case .clone:
                // TODO: BIT-365
                print("clone")
            case .moveToOrganization:
                // TODO: BIT-366
                print("moveToOrganization")
            }
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

    /// Copies a value to the pasteboard.
    ///
    /// - Parameter value: The string to be copied.
    ///
    func copyValue(_ value: String) {
        services.pasteboardService.copy(value)
    }

    /// Triggers the edit state for the item currently stored in `state`.
    ///
    private func editItem() {
        guard case let .data(cipherState) = state.loadingState,
              case let .existing(cipher) = cipherState.configuration else {
            return
        }
        coordinator.navigate(to: .editItem(cipher: cipher), context: self)
    }

    /// Soft Deletes the item currently stored in `state`.
    ///
    private func deleteItem(_ id: String) async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            coordinator.showLoadingOverlay(.init(title: Localizations.softDeleting))
            try await services.vaultRepository.deleteCipher(id)
            coordinator.navigate(to: .dismiss(DismissAction(action: { [weak self] in
                self?.delegate?.itemDeleted()
            })))
        } catch {
            let alert = Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                alertActions: [AlertAction(title: Localizations.ok, style: .default)]
            )
            coordinator.showAlert(alert)
            services.errorReporter.log(error: error)
        }
    }

    /// Handles `ViewCardItemAction` events.
    ///
    /// - Parameter cardAction: The action to handle.
    ///
    private func handleCardAction(_ cardAction: ViewCardItemAction) {
        guard case var .data(cipherState) = state.loadingState else {
            services.errorReporter.log(
                error: ActionError.dataNotLoaded("Cannot handle card action without loaded data")
            )
            return
        }
        guard case .card = cipherState.type else {
            services.errorReporter.log(
                error: ActionError.nonCardTypeToggle("Cannot handle card action on non-card type")
            )
            return
        }
        switch cardAction {
        case let .toggleCodeVisibilityChanged(isVisible):
            cipherState.cardItemState.isCodeVisible = isVisible
            state.loadingState = .data(cipherState)
        case let .toggleNumberVisibilityChanged(isVisible):
            cipherState.cardItemState.isNumberVisible = isVisible
            state.loadingState = .data(cipherState)
        }
    }

    /// Presents the master password re-prompt alert for the specified action. This method will
    /// process the action once the master password has been verified.
    ///
    /// - Parameter action: The action to process once the password has been verified.
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

    /// Shows delete cipher confirmation alert.
    ///
    private func showDeleteConfirmation() async {
        guard case let .data(cipherState) = state.loadingState else {
            return
        }
        let alert = Alert.deleteCipherConfirmation { [weak self] in
            guard let self else { return }
            if !cipherState.id.isEmpty {
                await deleteItem(cipherState.id)
            }
        }
        coordinator.showAlert(alert)
    }
}

// MARK: - CipherItemOperationDelegate

extension ViewItemProcessor: CipherItemOperationDelegate {
    func itemDeleted() {
        coordinator.navigate(to: .dismiss(DismissAction(action: { [weak self] in
            self?.delegate?.itemDeleted()
        })))
    }
}
