import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - AttachmentPreviewProcessor

/// The processor used to manage state and handle actions for `AttachmentPreviewView`.
///
class AttachmentPreviewProcessor: StateProcessor<
    AttachmentPreviewState,
    AttachmentPreviewAction,
    AttachmentPreviewEffect,
> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `AttachmentPreviewProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` for this processor.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>,
        services: Services,
        state: AttachmentPreviewState,
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    deinit {
        // When the preview and anything presented on top of it (e.g. the save file picker) are
        // dismissed, ensure any temporary files are deleted.
        services.vaultRepository.clearTemporaryDownloads()
    }

    // MARK: Methods

    override func perform(_ effect: AttachmentPreviewEffect) async {
        switch effect {
        case .downloadPressed:
            do {
                try restoreTemporaryFileIfNeeded()
                coordinator.navigate(to: .saveFile(temporaryUrl: state.temporaryUrl))
            } catch {
                coordinator.showAlert(.defaultAlert(title: Localizations.unableToDownloadFile))
                services.errorReporter.log(error: error)
            }
        }
    }

    override func receive(_ action: AttachmentPreviewAction) {
        switch action {
        case .dismissPressed:
            coordinator.navigate(to: .dismiss())
        }
    }

    // MARK: Private Methods

    /// Writes the image content back to `state.temporaryUrl` if its file was deleted after the
    /// image was loaded into memory, so that it can be saved by the user. The file is removed
    /// again when this processor is deallocated.
    ///
    private func restoreTemporaryFileIfNeeded() throws {
        let data: Data
        switch state.content {
        case let .animatedImage(imageData), let .image(imageData):
            data = imageData
        case .fileError, .unsupportedFileType:
            return
        }

        guard !FileManager.default.fileExists(atPath: state.temporaryUrl.path) else { return }
        try FileManager.default.createDirectory(
            at: state.temporaryUrl.deletingLastPathComponent(),
            withIntermediateDirectories: true,
        )
        try data.write(to: state.temporaryUrl, options: .atomic)
    }
}
