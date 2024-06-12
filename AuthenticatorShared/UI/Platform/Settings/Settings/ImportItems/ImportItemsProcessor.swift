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
        if let route = state.fileFormat.fileSelectionRoute {
            coordinator.navigate(to: .importItemsFileSelection(route: route), context: self)
        } else {
            Task {
                await coordinator.handleEvent(.importItemsQrCode, context: self)
            }
        }
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
                case .googleQr:
                    importFileFormat = .googleProtobuf
                case .lastpassJson:
                    importFileFormat = .lastpassJson
                case .raivoJson:
                    importFileFormat = .raivoJson
                case .twoFasJason:
                    importFileFormat = .twoFasJson
                }
                try await services.importItemsService.importItems(data: data, format: importFileFormat)
                state.toast = Toast(text: Localizations.itemsImported)
            } catch TwoFasImporterError.passwordProtectedFile {
                coordinator.showAlert(.twoFasPasswordProtected())
            } catch {
                services.errorReporter.log(error: error)
            }
        }
    }
}

extension ImportItemsProcessor: AuthenticatorKeyCaptureDelegate {
    func didCompleteAutomaticCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        key: String
    ) {
        let dismissAction = DismissAction(action: { [weak self] in
            Task {
                await self?.parseAndValidateAutomaticCaptureKey(key)
            }
        })
        captureCoordinator.navigate(to: .dismiss(dismissAction))
    }

    func parseAndValidateAutomaticCaptureKey(_ key: String) async {
        do {
            try await services.importItemsService.importItems(data: key.data(using: .utf8)!, format: .googleProtobuf)
            state.toast = Toast(text: Localizations.itemsImported)
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    func didCompleteManualCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        key: String,
        name: String
    ) {}

    func showCameraScan(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>
    ) {}

    func showManualEntry(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>
    ) {}
}
