import BitwardenKit
import BitwardenResources
@preconcurrency import BitwardenSdk
import Foundation

// MARK: - ViewItemProcessor

/// A processor that can process `ViewItemAction`s.
///
final class ViewItemProcessor: StateProcessor<ViewItemState, ViewItemAction, ViewItemEffect>, Rehydratable {
    // MARK: Types

    typealias Services = HasAPIService
        & HasAuthRepository
        & HasConfigService
        & HasEnvironmentService
        & HasErrorReporter
        & HasEventService
        & HasPasteboardService
        & HasRehydrationHelper
        & HasStateService
        & HasVaultRepository

    // MARK: Subtypes

    /// An error case for ViewItemAction errors.
    enum ActionError: Error, Equatable {
        /// An action that requires data has been performed while loading.
        case dataNotLoaded(String)

        /// An error for card action handling
        case nonCardTypeToggle(String)

        /// A password visibility toggle occurred when not possible.
        case nonLoginPasswordToggle(String)

        /// An error for ssh key action handling
        case nonSshKeyTypeToggle(String)
    }

    // MARK: Public properties

    var rehydrationState: RehydrationState? {
        RehydrationState(target: .viewCipher(cipherId: itemId))
    }

    // MARK: Private Properties

    /// The `Coordinator` for this processor.
    private let coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>

    /// The delegate that is notified when delete cipher item have occurred.
    private weak var delegate: CipherItemOperationDelegate?

    /// The ID of the item being viewed.
    private let itemId: String

    /// The services used by this processor.
    private let services: Services

    /// The task that streams cipher details.
    private(set) var streamCipherDetailsTask: Task<Void, Never>?

    // MARK: Initialization

    /// Creates a new `ViewItemProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` for this processor.
    ///   - delegate: The delegate that is notified when add/edit/delete cipher item have occurred.
    ///   - itemId: The id of the item that is being viewed.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>,
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
        Task {
            await self.services.rehydrationHelper.addRehydratableTarget(self)
        }
    }

    deinit {
        // When the view is dismissed, ensure any temporary files are deleted.
        services.vaultRepository.clearTemporaryDownloads()
    }

    // MARK: Methods

    override func perform(_ effect: ViewItemEffect) async {
        switch effect {
        case .appeared:
            streamCipherDetailsTask?.cancel()
            streamCipherDetailsTask = Task {
                await streamCipherDetails()
            }
        case .checkPasswordPressed:
            do {
                guard let password = state.loadingState.data?.cipher.login?.password else { return }
                let breachCount = try await services.apiService.checkDataBreaches(password: password)
                coordinator.showAlert(.dataBreachesCountAlert(count: breachCount))
            } catch {
                services.errorReporter.log(error: error)
            }
        case .deletePressed:
            guard case let .data(cipherState) = state.loadingState else { return }
            if cipherState.cipher.deletedDate == nil {
                await showSoftDeleteConfirmation(cipherState.cipher)
            } else {
                await showPermanentDeleteConfirmation(cipherState.cipher)
            }
        case .restorePressed:
            await showRestoreItemConfirmation()
        case .toggleDisplayMultipleCollections:
            toggleDisplayMultipleCollections()
        case .totpCodeExpired:
            await updateTOTPCode()
        }
    }

    override func receive(_ action: ViewItemAction) { // swiftlint:disable:this function_body_length
        switch action {
        case let .cardItemAction(cardAction):
            handleCardAction(cardAction)
        case let .copyPressed(value, field):
            copyValue(value, field)
        case let .customFieldVisibilityPressed(customFieldState):
            guard case var .data(cipherState) = state.loadingState else {
                services.errorReporter.log(
                    error: ActionError.dataNotLoaded("Cannot toggle password for non-loaded item.")
                )
                return
            }
            cipherState.togglePasswordVisibility(for: customFieldState)
            state.loadingState = .data(cipherState)
            if !customFieldState.isPasswordVisible { // The state before we toggled it
                Task {
                    await services.eventService.collect(
                        eventType: .cipherClientToggledHiddenFieldVisible,
                        cipherId: cipherState.cipher.id
                    )
                }
            }
        case .disappeared:
            streamCipherDetailsTask?.cancel()
            streamCipherDetailsTask = nil
        case .dismissPressed:
            coordinator.navigate(to: .dismiss())
        case let .downloadAttachment(attachment):
            confirmDownload(attachment)
        case .editPressed:
            editItem()
        case let .morePressed(menuAction):
            handleMenuAction(menuAction)
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
            if cipherState.loginState.isPasswordVisible {
                Task {
                    await services.eventService.collect(
                        eventType: .cipherClientToggledPasswordVisible,
                        cipherId: cipherState.cipher.id
                    )
                }
            }
        case .passwordHistoryPressed:
            guard let passwordHistory = state.passwordHistory else { return }
            coordinator.navigate(to: .passwordHistory(passwordHistory))
        case let .sshKeyItemAction(sshKeyAction):
            handleSSHKeyAction(sshKeyAction)
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }
}

private extension ViewItemProcessor {
    // MARK: Private Methods

    /// Navigates to the clone item view. If the cipher contains FIDO2 credentials, an alert is
    /// shown confirming that the user wants to proceed cloning the cipher without a FIDO2 credential.
    ///
    /// - Parameter cipher: The cipher to clone.
    ///
    private func cloneItem(_ cipher: CipherView) async {
        let hasPremium = await services.vaultRepository.doesActiveAccountHavePremium()
        if cipher.login?.fido2Credentials?.isEmpty == false {
            coordinator.showAlert(.confirmCloneExcludesFido2Credential {
                self.coordinator.navigate(to: .cloneItem(cipher: cipher, hasPremium: hasPremium), context: self)
            })
        } else {
            coordinator.navigate(to: .cloneItem(cipher: cipher, hasPremium: hasPremium), context: self)
        }
    }

    /// Present an alert to confirm downloading large attachments.
    ///
    /// - Parameter attachment: The attachment to download.
    ///
    private func confirmDownload(_ attachment: AttachmentView) {
        // If the attachment is larger than 10 MB, make the user confirm downloading it.
        if let sizeName = attachment.sizeName,
           let size = Int(attachment.size ?? ""),
           size >= Constants.largeFileSize {
            coordinator.showAlert(.confirmDownload(fileSize: sizeName) {
                await self.downloadAttachment(attachment)
            })
        } else {
            Task { await downloadAttachment(attachment) }
        }
    }

    /// Copies a value to the pasteboard and shows a toast for the field that was copied.
    ///
    /// - Parameters:
    ///   - value: The string to be copied.
    ///   - field: The field being copied.
    ///
    private func copyValue(_ value: String, _ field: CopyableField?) {
        guard case let .data(cipherState) = state.loadingState else {
            services.errorReporter.log(
                error: ActionError.dataNotLoaded("Cannot copy value for non-loaded item.")
            )
            return
        }

        services.pasteboardService.copy(value)

        let localizedFieldName = field?.localizedName ?? Localizations.value
        state.toast = Toast(title: Localizations.valueHasBeenCopied(localizedFieldName))
        if let event = field?.eventOnCopy {
            Task {
                await services.eventService.collect(
                    eventType: event,
                    cipherId: cipherState.cipher.id
                )
            }
        }
    }

    /// Download the attachment.
    ///
    /// - Parameter attachment: The attachment to download.
    ///
    private func downloadAttachment(_ attachment: AttachmentView) async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            guard case let .data(cipherState) = state.loadingState else { return }
            coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.downloading))

            guard let temporaryUrl = try await services.vaultRepository.downloadAttachment(
                attachment,
                cipher: cipherState.cipher
            ) else {
                return coordinator.showAlert(.defaultAlert(title: Localizations.unableToDownloadFile))
            }

            coordinator.hideLoadingOverlay()
            coordinator.navigate(to: .saveFile(temporaryUrl: temporaryUrl))
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.unableToDownloadFile))
            services.errorReporter.log(error: error)
        }
    }

    /// Triggers the edit state for the item currently stored in `state`.
    ///
    private func editItem() {
        guard case let .data(cipherState) = state.loadingState,
              case let .existing(cipher) = cipherState.configuration else {
            return
        }
        Task {
            let hasPremium = await services.vaultRepository.doesActiveAccountHavePremium()
            coordinator.navigate(to: .editItem(cipher, hasPremium), context: self)
        }
    }

    /// Permanently deletes the item currently stored in `state`.
    ///
    private func permanentDeleteItem(id: String) async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            coordinator.showLoadingOverlay(.init(title: Localizations.deleting))

            try await services.vaultRepository.deleteCipher(id)
            coordinator.navigate(to: .dismiss(DismissAction(action: { [weak self] in
                self?.delegate?.itemDeleted()
            })))
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }

    /// Soft deletes the item currently stored in `state`.
    ///
    private func softDeleteItem(_ cipher: CipherView) async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            coordinator.showLoadingOverlay(.init(title: Localizations.softDeleting))

            try await services.vaultRepository.softDeleteCipher(cipher)
            coordinator.navigate(to: .dismiss(DismissAction(action: { [weak self] in
                self?.delegate?.itemSoftDeleted()
            })))
        } catch {
            await coordinator.showErrorAlert(error: error)
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
            if isVisible {
                Task {
                    await services.eventService.collect(
                        eventType: .cipherClientToggledCardCodeVisible,
                        cipherId: cipherState.cipher.id
                    )
                }
            }
        case let .toggleNumberVisibilityChanged(isVisible):
            cipherState.cardItemState.isNumberVisible = isVisible
            state.loadingState = .data(cipherState)
            if isVisible {
                Task {
                    await services.eventService.collect(
                        eventType: .cipherClientToggledCardNumberVisible,
                        cipherId: cipherState.cipher.id
                    )
                }
            }
        }
    }

    /// Handles an action associated with the `VaultItemManagementMenuAction` menu.
    ///
    /// - Parameter action: The action that was sent from the menu.
    ///
    private func handleMenuAction(_ action: VaultItemManagementMenuAction) {
        guard let cipher = state.loadingState.data?.cipher else {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(
                error: ActionError.dataNotLoaded("Cannot perform action on cipher until it's loaded.")
            )
            return
        }

        switch action {
        case .attachments:
            coordinator.navigate(to: .attachments(cipher))
        case .clone:
            Task {
                await cloneItem(cipher)
            }
        case .editCollections:
            coordinator.navigate(to: .editCollections(cipher), context: self)
        case .moveToOrganization:
            coordinator.navigate(to: .moveToOrganization(cipher), context: self)
        }
    }

    /// Handles `ViewSSHKeyItemAction` events.
    /// - Parameter sshKeyAction: The action to handle
    private func handleSSHKeyAction(_ sshKeyAction: ViewSSHKeyItemAction) {
        guard case var .data(cipherState) = state.loadingState else {
            services.errorReporter.log(
                error: ActionError.dataNotLoaded("Cannot handle SSH key action without loaded data")
            )
            return
        }
        guard case .sshKey = cipherState.type else {
            services.errorReporter.log(
                error: ActionError.nonSshKeyTypeToggle("Cannot handle SSH key action on non SSH key type")
            )
            return
        }
        switch sshKeyAction {
        case let .copyPressed(value, field):
            copyValue(value, field)
        case .privateKeyVisibilityPressed:
            cipherState.sshKeyState.isPrivateKeyVisible.toggle()
            state.loadingState = .data(cipherState)
            // TODO: PM-11977 Collect visibility toggled event
        }
    }

    /// Restores the item currently stored in `state`.
    ///
    private func restoreItem(_ cipher: CipherView) async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            coordinator.showLoadingOverlay(.init(title: Localizations.restoring))

            try await services.vaultRepository.restoreCipher(cipher)
            coordinator.navigate(to: .dismiss(DismissAction(action: { [weak self] in
                self?.delegate?.itemRestored()
            })))
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }

    /// Shows a permanent delete cipher confirmation alert.
    ///
    private func showPermanentDeleteConfirmation(_ cipher: CipherView) async {
        guard let id = cipher.id else { return }
        let alert = Alert.deleteCipherConfirmation(isSoftDelete: false) { [weak self] in
            guard let self else { return }
            await permanentDeleteItem(id: id)
        }
        coordinator.showAlert(alert)
    }

    /// Shows a soft delete cipher confirmation alert.
    ///
    private func showSoftDeleteConfirmation(_ cipher: CipherView) async {
        let alert = Alert.deleteCipherConfirmation(isSoftDelete: true) { [weak self] in
            guard let self else { return }
            await softDeleteItem(cipher)
        }
        coordinator.showAlert(alert)
    }

    /// Shows restore cipher confirmation alert.
    ///
    private func showRestoreItemConfirmation() async {
        guard case let .data(cipherState) = state.loadingState else { return }
        let alert = Alert(
            title: Localizations.doYouReallyWantToRestoreCipher,
            message: nil,
            alertActions: [
                AlertAction(
                    title: Localizations.yes,
                    style: .default,
                    handler: { [weak self] _ in
                        guard let self else { return }
                        await restoreItem(cipherState.cipher)
                    }
                ),
                AlertAction(title: Localizations.cancel, style: .cancel),
            ]
        )
        coordinator.showAlert(alert)
    }

    /// Stream the cipher details.
    private func streamCipherDetails() async {
        do {
            await services.eventService.collect(eventType: .cipherClientViewed, cipherId: itemId)
            for try await cipher in try await services.vaultRepository.cipherDetailsPublisher(id: itemId) {
                guard let cipher else { continue }

                let hasPremium = await services.vaultRepository.doesActiveAccountHavePremium()
                let collections = try await services.vaultRepository.fetchCollections(includeReadOnly: true)
                var folder: FolderView?
                if let folderId = cipher.folderId {
                    folder = try await services.vaultRepository.fetchFolder(withId: folderId)
                }
                var organization: Organization?
                if let orgId = cipher.organizationId {
                    organization = try await services.vaultRepository.fetchOrganization(withId: orgId)
                }
                let showWebIcons = await services.stateService.getShowWebIcons()

                var totpState = LoginTOTPState(cipher.login?.totp)
                if let key = totpState.authKeyModel,
                   let updatedState = try? await services.vaultRepository.refreshTOTPCode(for: key) {
                    totpState = updatedState
                }

                guard var newState = ViewItemState(
                    cipherView: cipher,
                    hasPremium: hasPremium,
                    iconBaseURL: services.environmentService.iconsURL
                ) else { continue }

                if case var .data(itemState) = newState.loadingState {
                    itemState.loginState.totpState = totpState
                    itemState.allUserCollections = collections
                    itemState.folderName = folder?.name
                    itemState.organizationName = organization?.name
                    itemState.showWebIcons = showWebIcons
                    newState.loadingState = .data(itemState)
                }
                state = newState
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Toggles whether to show one or multiple collections the cipher belongs to, if any.
    private func toggleDisplayMultipleCollections() {
        guard case var .data(cipherState) = state.loadingState,
              !cipherState.cipherCollections.isEmpty else {
            return
        }

        cipherState.isShowingMultipleCollections.toggle()

        state.loadingState = .data(cipherState)
    }
}

// MARK: TOTP

private extension ViewItemProcessor {
    /// Updates the TOTP code for the view.
    func updateTOTPCode() async {
        // Only update the code if the user has premium and there is a valid TOTP key model.
        guard state.hasPremiumFeatures,
              case let .data(cipherItemState) = state.loadingState,
              let calculationKey = cipherItemState.loginState.totpState.authKeyModel
        else { return }
        do {
            // Get an updated TOTP code for the present key model.
            let newLoginTOTP = try await services.vaultRepository.refreshTOTPCode(for: calculationKey)

            // Don't update the state if the state is presently loading.
            guard case let .data(cipherItemState) = state.loadingState else { return }

            // Make a copy for the update.
            var updatedState = cipherItemState

            // Update the copy with the new TOTP state.
            updatedState.loginState.totpState = newLoginTOTP

            // Set the loading state with the updated model.
            state.loadingState = .data(updatedState)
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}

// MARK: - CipherItemOperationDelegate

extension ViewItemProcessor: CipherItemOperationDelegate {
    func itemDeleted() {
        coordinator.navigate(to: .dismiss(DismissAction(action: { [weak self] in
            self?.delegate?.itemDeleted()
        })))
    }

    func itemRestored() {
        delegate?.itemRestored()
    }

    func itemSoftDeleted() {
        coordinator.navigate(to: .dismiss(DismissAction(action: { [weak self] in
            self?.delegate?.itemSoftDeleted()
        })))
    }
}

// MARK: - EditCollectionsProcessorDelegate

extension ViewItemProcessor: EditCollectionsProcessorDelegate {
    func didUpdateCipher() {
        state.toast = Toast(title: Localizations.itemUpdated)
    }
}

// MARK: - MoveToOrganizationProcessorDelegate

extension ViewItemProcessor: MoveToOrganizationProcessorDelegate {
    func didMoveCipher(_ cipher: CipherView, to organization: CipherOwner) {
        state.toast = Toast(title: Localizations.movedItemToOrg(cipher.name, organization.localizedName))
    }
} // swiftlint:disable:this file_length
