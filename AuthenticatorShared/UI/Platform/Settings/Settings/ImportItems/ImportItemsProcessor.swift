import Foundation

// MARK: - ImportItemsProcessor

/// The processor used to manage state and handle actions for an `ImportItemsView`.
final class ImportItemsProcessor: StateProcessor<ImportItemsState, ImportItemsAction, ImportItemsEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasImportItemsService

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `ImportItemsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: ImportItemsState())
    }

    // MARK: Methods

    override func perform(_ effect: ImportItemsEffect) async {
        switch effect {
        case .loadData:
            break
        }
    }

    override func receive(_ action: ImportItemsAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case .importItemsTapped:
            showImportItemsFileSelection()
        case let .fileFormatTypeChanged(fileFormat):
            state.fileFormat = fileFormat
        case let .toastShown(toast):
            state.toast = toast
        }
    }

    // MARK: - Private Methods

    /// Show the dialog to select file to import.
    private func showImportItemsFileSelection() {
        coordinator.navigate(to: .importItemsFileSelection(route: state.fileFormat.fileSelectionRoute), context: self)
    }
}

extension ImportItemsProcessor: FileSelectionDelegate {
    func fileSelectionCompleted(fileName: String, data: Data) {
        Task {
            do {
                let importFileFormat: ImportFileFormat
                switch state.fileFormat {
                case .bitwardenJson:
                    importFileFormat = .bitwardenJson
                case .raivoJson:
                    importFileFormat = .raivoJson
                }
                try await services.importItemsService.importItems(data: data, format: importFileFormat)
                state.toast = Toast(text: Localizations.itemsImported)
            } catch {
                services.errorReporter.log(error: error)
            }
        }
    }
}
