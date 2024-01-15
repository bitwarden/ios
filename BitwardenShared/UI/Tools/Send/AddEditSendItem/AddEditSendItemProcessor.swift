import Foundation

// MARK: - AddEditSendItemProcessor

/// The processor used to manage state and handle actions for the add/edit send item screen.
///
class AddEditSendItemProcessor: StateProcessor<AddEditSendItemState, AddEditSendItemAction, AddEditSendItemEffect> {
    // MARK: Types

    typealias Services = HasSendRepository

    // MARK: Properties

    /// The `Coordinator` that handles navigation for this processor.
    let coordinator: any Coordinator<SendRoute>

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
        coordinator: any Coordinator<SendRoute>,
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
        case .savePressed:
            await saveSendItem()
        }
    }

    override func receive(_ action: AddEditSendItemAction) {
        switch action {
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
            state.type = newValue
        }
    }

    // MARK: Private Methods

    /// Saves the current send item.
    ///
    private func saveSendItem() async {
        guard !state.name.isEmpty else {
            let alert = Alert.validationFieldRequired(fieldName: Localizations.name)
            coordinator.showAlert(alert)
            return
        }

        coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.saving))
        defer { coordinator.hideLoadingOverlay() }

        let sendView = state.newSendView()
        do {
            try await services.sendRepository.addSend(sendView)
            coordinator.hideLoadingOverlay()
            coordinator.navigate(to: .dismiss)
        } catch {
            coordinator.showAlert(.networkResponseError(error) { [weak self] in
                await self?.saveSendItem()
            })
        }
    }
}
