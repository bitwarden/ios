// MARK: - FoldersProcessor

/// The processor used to manage state and handle actions for the `FoldersView`.
///
final class FoldersProcessor: StateProcessor<FoldersState, FoldersAction, FoldersEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasSettingsRepository

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `FoldersProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        services: Services,
        state: FoldersState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: FoldersEffect) async {
        switch effect {
        case .streamFolders:
            await streamFolders()
        }
    }

    override func receive(_ action: FoldersAction) {
        switch action {
        case .add:
            coordinator.navigate(to: .addEditFolder(folder: nil), context: self)
        case let .folderTapped(folderID):
            guard let folder = state.folders.first(where: { $0.id == folderID }) else { return }
            coordinator.navigate(to: .addEditFolder(folder: folder), context: self)
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Stream the list of folders
    private func streamFolders() async {
        do {
            let publisher = try await services.settingsRepository.foldersListPublisher()
            for try await value in publisher {
                state.folders = value
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}

// MARK: - CaptchaFlowDelegate

extension FoldersProcessor: AddEditFolderDelegate {
    /// Show the toast that the folder was successfully added.
    func folderAdded() {
        state.toast = Toast(text: Localizations.folderCreated)
    }

    /// Show the toast that the folder was successfully deleted.
    func folderDeleted() {
        state.toast = Toast(text: Localizations.folderDeleted)
    }

    /// Show the toast that the folder was successfully edited.
    func folderEdited() {
        state.toast = Toast(text: Localizations.folderUpdated)
    }
}
