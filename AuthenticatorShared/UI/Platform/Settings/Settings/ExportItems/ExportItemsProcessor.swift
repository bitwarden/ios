import Foundation

// MARK: - ExportItemsProcessor

/// The processor used to manage state and handle actions for an `ExportItemsView`.
final class ExportItemsProcessor: StateProcessor<ExportItemsState, ExportItemsAction, ExportItemsEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasExportItemsService

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `ExportItemsProcessor`.
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
        super.init(state: ExportItemsState())
    }

    deinit {
        // When the view is dismissed, ensure any temporary files are deleted.
        services.exportItemsService.clearTemporaryFiles()
    }

    // MARK: Methods

    override func perform(_ effect: ExportItemsEffect) async {
        switch effect {
        case .loadData:
            break
        }
    }

    override func receive(_ action: ExportItemsAction) {
        switch action {
        case .dismiss:
            services.exportItemsService.clearTemporaryFiles()
            coordinator.navigate(to: .dismiss)
        case .exportItemsTapped:
            confirmExportItems()
        case let .fileFormatTypeChanged(fileFormat):
            state.fileFormat = fileFormat
        }
    }

    // MARK: - Private Methods

    /// Shows the alert to confirm the items export.
    private func confirmExportItems() {
        let exportFormat: ExportFileType
        switch state.fileFormat {
        case .csv:
            exportFormat = .csv
        case .json:
            exportFormat = .json
        }

        coordinator.showAlert(.confirmExportItems {
            do {
                let fileUrl = try await self.services.exportItemsService.exportItems(format: exportFormat)
                self.coordinator.navigate(to: .shareExportedItems(fileUrl))
            } catch {
                self.services.errorReporter.log(error: error)
            }
        })
    }
}
