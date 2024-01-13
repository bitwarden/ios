import Foundation

// MARK: - AddEditSendItemProcessor

/// The processor used to manage state and handle actions for the add/edit send item screen.
///
class AddEditSendItemProcessor: StateProcessor<AddEditSendItemState, AddEditSendItemAction, AddEditSendItemEffect> {
    // MARK: Properties

    /// The `Coordinator` that handles navigation for this processor.
    let coordinator: any Coordinator<SendRoute>

    // MARK: Initialization

    /// Creates a new `AddEditSendItemProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation for this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: any Coordinator<SendRoute>,
        state: AddEditSendItemState
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AddEditSendItemEffect) async {
        switch effect {
        case .savePressed:
            await saveSendItem()
        }
    }

    override func receive(_ action: AddEditSendItemAction) {
        switch action {
        case .chooseFilePressed:
            print("choose file")
        case let .customDeletionDateChanged(newValue):
            state.customDeletionDate = newValue
        case let .customExpirationDateChanged(newValue):
            state.customExpirationDate = newValue
        case let .deactivateThisSendChanged(newValue):
            state.isDeactivateThisSendOn = newValue
        case let .deletionDateChanged(newValue):
            state.deletionDate = newValue
        case let .expirationDateChanged(newValue):
            state.expirationDate = newValue
        case .dismissPressed:
            coordinator.navigate(to: .dismiss)
        case let .hideMyEmailChanged(newValue):
            state.isHideMyEmailOn = newValue
        case let .hideTextByDefaultChanged(newValue):
            state.isHideTextByDefaultOn = newValue
        case .optionsPressed:
            state.isOptionsExpanded.toggle()
        case let .passwordChanged(newValue):
            state.password = newValue
        case let .passwordVisibileChanged(newValue):
            state.isPasswordVisible = newValue
        case let .maximumAccessCountChanged(newValue):
            state.maximumAccessCount = newValue
        case let .nameChanged(newValue):
            state.name = newValue
        case let .notesChanged(newValue):
            state.notes = newValue
        case let .shareOnSaveChanged(newValue):
            state.isShareOnSaveOn = newValue
        case let .textChanged(newValue):
            state.text = newValue
        case let .typeChanged(newValue):
            updateType(newValue)
        }
    }

    // MARK: Private Methods

    /// Saves the current send item.
    ///
    private func saveSendItem() async {
        coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.saving))
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        coordinator.hideLoadingOverlay()
        coordinator.navigate(to: .dismiss)
    }

    /// Attempts to update the send type. If the active account does not have premium access, this
    /// method will display an alert informing the user that they do not have access to this
    /// feature.
    ///
    /// - Parameter newValue: The new value for the Send's type that will be attempted to be set.
    ///
    private func updateType(_ newValue: SendType) {
        guard state.hasPremium else {
            coordinator.showAlert(.defaultAlert(title: Localizations.sendFilePremiumRequired))
            return
        }
        state.type = newValue
    }
}
