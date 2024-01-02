// MARK: - AddEditFolderProcessor

/// The processor used to manage state and handle actions for the `AddEditFoldersView`.
///
final class AddEditFolderProcessor: StateProcessor<AddEditFolderState, AddEditFolderAction, AddEditFolderEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasSettingsRepository

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    /// The services used by this processor.
    private let services: Services

    /// Initializes an `AddFolderProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        services: Services,
        state: AddEditFolderState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AddEditFolderEffect) async {
        switch effect {
        case .deleteTapped:
            await showDeleteConfirmationAlert()
        case .saveTapped:
            await handleSaveTapped()
        }
    }

    override func receive(_ action: AddEditFolderAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .folderNameTextChanged(text):
            state.folderName = text
        }
    }

    // MARK: Private Methods

    /// Adds a new folder with the entered name and closes the view.
    private func addFolder() async throws {
        try await services.settingsRepository.addFolder(name: state.folderName)
        coordinator.navigate(to: .dismiss)
    }

    /// Deletes a folder.
    ///
    /// - Parameter id: The id of the folder to delete.
    ///
    private func deleteFolder(withID id: String) async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            coordinator.showLoadingOverlay(title: Localizations.deleting)
            try await services.settingsRepository.deleteFolder(id: id)
            coordinator.navigate(to: .dismiss)
        } catch {
            coordinator.showAlert(.networkResponseError(error) {
                await self.deleteFolder(withID: id)
            })
            services.errorReporter.log(error: error)
        }
    }

    /// Edits an existing folder with the entered name and closes the view.
    ///
    /// - Parameter folderID: The id of the folder to edit.
    ///
    private func editFolder(withID id: String) async throws {
        try await services.settingsRepository.editFolder(withID: id, name: state.folderName)
        coordinator.navigate(to: .dismiss)
    }

    /// Saves the folder either by adding a new folder or editing an existing folder.
    private func handleSaveTapped() async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            try EmptyInputValidator(fieldName: Localizations.name)
                .validate(input: state.folderName)
            coordinator.showLoadingOverlay(title: Localizations.saving)
            switch state.mode {
            case .add:
                try await addFolder()
            case let .edit(folder):
                try await editFolder(withID: folder.id)
            }
        } catch let error as InputValidationError {
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
        } catch {
            coordinator.showAlert(.networkResponseError(error) {
                await self.handleSaveTapped()
            })
            services.errorReporter.log(error: error)
        }
    }

    /// Show the dialog to confirm deleting the folder.
    private func showDeleteConfirmationAlert() async {
        guard case let .edit(folderView) = state.mode else { return }

        coordinator.showAlert(.confirmDeleteFolder { [weak self] in
            await self?.deleteFolder(withID: folderView.id)
        })
    }
}
