import BitwardenKit
import BitwardenResources
@preconcurrency import BitwardenSdk
import Foundation

// MARK: - AddEditSendItemProcessor

/// The processor used to manage state and handle actions for the add/edit send item screen.
///
class AddEditSendItemProcessor:
    StateProcessor<AddEditSendItemState, AddEditSendItemAction, AddEditSendItemEffect> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasConfigService
        & HasErrorReporter
        & HasPasteboardService
        & HasPolicyService
        & HasReviewPromptService
        & HasSendRepository

    // MARK: Private Properties

    /// A block to execute the next time the toast is cleared. This value is cleared once the block
    /// is executed once.
    private var onNextToastClear: (() -> Void)?

    // MARK: Properties

    /// The `Coordinator` that handles navigation for this processor.
    let coordinator: AnyCoordinator<SendItemRoute, AuthAction>

    /// The services required by this processor.
    let services: Services

    // MARK: Initialization

    /// Creates a new `AddEditSendItemProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation for this processor.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: AnyCoordinator<SendItemRoute, AuthAction>,
        services: Services,
        state: AddEditSendItemState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AddEditSendItemEffect) async {
        switch effect {
        case .copyLinkPressed:
            guard let sendView = state.originalSendView else { return }
            await copyLink(to: sendView)
        case .deletePressed:
            guard let sendView = state.originalSendView else { return }
            let alert = Alert.confirmationDestructive(title: Localizations.areYouSureDeleteSend) { [weak self] in
                await self?.deleteSend(sendView)
            }
            coordinator.showAlert(alert)
        case .loadData:
            await loadData()
        case let .profileSwitcher(profileEffect):
            await handle(profileEffect)
        case .removePassword:
            guard let sendView = state.originalSendView else { return }
            let alert = Alert.confirmationDestructive(
                title: Localizations.areYouSureRemoveSendPassword,
                destructiveTitle: Localizations.remove
            ) { [weak self] in
                await self?.removePassword(sendView)
            }
            coordinator.showAlert(alert)
        case .savePressed:
            await saveSendItem()
        case .shareLinkPressed:
            guard let sendView = state.originalSendView else { return }
            await shareSaveURL(sendView)
        }
    }

    override func receive(_ action: AddEditSendItemAction) {
        switch action {
        case .chooseFilePressed:
            presentFileSelectionAlert()
        case let .deletionDateChanged(newValue):
            state.deletionDate = newValue
        case .dismissPressed:
            coordinator.navigate(to: .cancel)
        case let .hideMyEmailChanged(newValue):
            state.isHideMyEmailOn = newValue
        case let .hideTextByDefaultChanged(newValue):
            state.isHideTextByDefaultOn = newValue
        case .optionsPressed:
            state.isOptionsExpanded.toggle()
        case let .passwordChanged(newValue):
            state.password = newValue
        case let .passwordVisibleChanged(newValue):
            state.isPasswordVisible = newValue
        case let .profileSwitcher(profileAction):
            handle(profileAction)
        case let .maximumAccessCountStepperChanged(newValue):
            state.maximumAccessCount = newValue
            state.maximumAccessCountText = "\(state.maximumAccessCount)"
        case let .nameChanged(newValue):
            state.name = newValue
        case let .notesChanged(newValue):
            state.notes = newValue
        case let .textChanged(newValue):
            state.text = newValue
        case let .toastShown(toast):
            state.toast = toast
            if toast == nil {
                onNextToastClear?()
                onNextToastClear = nil
            }
        }
    }

    // MARK: Private Methods

    /// Copies the share link for the provided send.
    ///
    /// - Parameter sendView: The send to copy the link to.
    ///
    private func copyLink(to sendView: SendView) async {
        guard let url = try? await services.sendRepository.shareURL(for: sendView) else { return }

        services.pasteboardService.copy(url.absoluteString)
        state.toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.sendLink))
    }

    /// Deletes the provided send.
    ///
    /// - Parameter sendView: The send to be deleted.
    ///
    private func deleteSend(_ sendView: SendView) async {
        coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.deleting))
        do {
            try await services.sendRepository.deleteSend(sendView)
            coordinator.hideLoadingOverlay()
            coordinator.navigate(to: .deleted)
        } catch {
            coordinator.hideLoadingOverlay()
            await coordinator.showErrorAlert(error: error) {
                await self.deleteSend(sendView)
            }
        }
    }

    /// Load any initial data for the view.
    ///
    private func loadData() async {
        state.isSendDisabled = await services.policyService.policyAppliesToUser(.disableSend)
        state.isSendHideEmailDisabled = await services.policyService.isSendHideEmailDisabledByPolicy()
        await refreshProfileState()

        if state.maximumAccessCount != 0 {
            state.maximumAccessCountText = "\(state.maximumAccessCount)"
        }
    }

    /// A method to respond to a `ProfileSwitcherAction`
    ///    No-Op unless the `state.mode` is `.shareExtension` with a `ProfileSwitcherState`.
    ///
    /// - Parameter profileAction: The action to be handled.
    ///
    private func handle(_ profileAction: ProfileSwitcherAction) {
        guard case .shareExtension = state.mode else { return }
        handleProfileSwitcherAction(profileAction)
    }

    /// A method to respond to a `ProfileSwitcherEffect`
    ///    No-Op unless the `state.mode` is `.shareExtension` with a `ProfileSwitcherState`.
    ///
    /// - Parameter profileAction: The action to be handled.
    ///
    private func handle(_ profileEffect: ProfileSwitcherEffect) async {
        guard case .shareExtension = state.mode else { return }
        switch profileEffect {
        case .accountLongPressed,
             .addAccountPressed:
            // No-Op for the extension
            break
        default:
            await handleProfileSwitcherEffect(profileEffect)
        }
    }

    /// Presents the file selection alert.
    ///
    private func presentFileSelectionAlert() {
        let alert = Alert.fileSelectionOptions { [weak self] route in
            guard let self else { return }
            coordinator.navigate(to: .fileSelection(route), context: self)
        }
        coordinator.showAlert(alert)
    }

    /// Removes the password from the provided send.
    ///
    /// - Parameter sendView: The send to remove the password from.
    ///
    private func removePassword(_ sendView: SendView) async {
        coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.removingSendPassword))
        do {
            let newSend = try await services.sendRepository.removePassword(from: sendView)
            var newState = AddEditSendItemState(sendView: newSend)
            newState.isOptionsExpanded = state.isOptionsExpanded
            state = newState

            coordinator.hideLoadingOverlay()
            state.toast = Toast(title: Localizations.sendPasswordRemoved)
        } catch {
            coordinator.hideLoadingOverlay()
            await coordinator.showErrorAlert(error: error) {
                await self.removePassword(sendView)
            }
        }
    }

    /// Saves the current send item.
    ///
    private func saveSendItem() async {
        guard await validateSend() else { return }

        coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.saving))
        defer { coordinator.hideLoadingOverlay() }

        let sendView = state.newSendView()
        do {
            let newSendView: SendView
            switch state.mode {
            case .add, .shareExtension:
                switch state.type {
                case .file:
                    guard let fileData = state.fileData else { return }
                    newSendView = try await services.sendRepository.addFileSend(sendView, data: fileData)
                case .text:
                    newSendView = try await services.sendRepository.addTextSend(sendView)
                }
                await services.reviewPromptService.trackUserAction(.createdNewSend)
            case .edit:
                newSendView = try await services.sendRepository.updateSend(sendView)
            }
            coordinator.hideLoadingOverlay()
            switch state.mode {
            case .add:
                coordinator.navigate(to: .complete(newSendView))
                coordinator.showToast(Localizations.newSendCreated)
            case .edit:
                coordinator.navigate(to: .complete(newSendView))
                coordinator.showToast(Localizations.sendUpdated)
            case .shareExtension:
                onNextToastClear = { [weak self] in
                    self?.coordinator.navigate(to: .complete(newSendView))
                }
                await copyLink(to: newSendView)
            }
        } catch {
            await coordinator.showErrorAlert(error: error) {
                await self.saveSendItem()
            }
        }
    }

    /// Navigates to the `.share` route for the provided send view.
    ///
    /// - Parameter sendView: The send that is being shared.
    ///
    private func shareSaveURL(_ sendView: SendView) async {
        guard let url = try? await services.sendRepository.shareURL(for: sendView)
        else { return }

        coordinator.navigate(to: .share(url: url))
    }

    /// Validates that the content in the state comprises a valid send. If any validation issue is
    /// found, an alert will be presented.
    ///
    /// - Returns: A flag indicating if the state holds valid information for creating a send.
    ///
    private func validateSend() async -> Bool {
        guard !state.name.isEmpty else {
            let alert = Alert.validationFieldRequired(fieldName: Localizations.name)
            coordinator.showAlert(alert)
            return false
        }

        // Only perform further checks for file sends.
        guard state.type == .file else { return true }

        let hasPremium = await services.sendRepository.doesActiveAccountHavePremium()
        guard hasPremium else {
            let alert = Alert.defaultAlert(
                message: Localizations.sendFilePremiumRequired
            )
            coordinator.showAlert(alert)
            return false
        }

        let isEmailVerified = try? await services.sendRepository.doesActiveAccountHaveVerifiedEmail()
        guard isEmailVerified ?? false else {
            let alert = Alert.defaultAlert(
                message: Localizations.sendFileEmailVerificationRequired
            )
            coordinator.showAlert(alert)
            return false
        }

        // Only perform further checks when adding a new file send.
        guard state.mode == .add else { return true }

        guard let fileData = state.fileData, state.fileName != nil else {
            let alert = Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.youMustAttachAFileToSaveThisSend
            )
            coordinator.showAlert(alert)
            return false
        }

        guard fileData.count <= Constants.maxFileSizeBytes else {
            let alert = Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.maxFileSize
            )
            coordinator.showAlert(alert)
            return false
        }

        return true
    }
}

// MARK: - AddEditSendItemProcessor:FileSelectionDelegate

extension AddEditSendItemProcessor: FileSelectionDelegate {
    func fileSelectionCompleted(fileName: String, data: Data) {
        state.fileName = fileName
        state.fileData = data
    }
}

// MARK: - ProfileSwitcherHandler

extension AddEditSendItemProcessor: ProfileSwitcherHandler {
    var allowLockAndLogout: Bool {
        false
    }

    var profileServices: ProfileServices {
        services
    }

    var profileSwitcherState: ProfileSwitcherState {
        get {
            guard case let .shareExtension(profileState) = state.mode else {
                return .empty()
            }
            return profileState
        }
        set {
            guard case .shareExtension = state.mode else {
                return
            }
            state.mode = .shareExtension(newValue)
        }
    }

    var shouldHideAddAccount: Bool {
        true
    }

    var toast: Toast? {
        get {
            state.toast
        }
        set {
            state.toast = newValue
        }
    }

    func handleAuthEvent(_ authEvent: AuthEvent) async {
        guard case let .action(authAction) = authEvent else { return }
        await coordinator.handleEvent(authAction)
    }

    func showAddAccount() {
        // No-Op for the AddEditSendItemProcessor.
    }

    func showAlert(_ alert: Alert) {
        coordinator.showAlert(alert)
    }
} // swiftlint:disable:this file_length
