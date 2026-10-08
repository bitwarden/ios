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
            if let temporaryUrl = state.temporaryUrl {
                saveFile(at: temporaryUrl)
            } else {
                await confirmDownload()
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

    /// Downloads the attachment, after confirming with the user if it's large, and then presents
    /// the save file picker. This is used for files that can't be previewed, which aren't
    /// downloaded until the user asks for them.
    ///
    private func confirmDownload() async {
        if let sizeName = state.attachment.sizeName,
           let size = Int(state.attachment.size ?? ""),
           size >= Constants.largeFileSize {
            coordinator.showAlert(.confirmDownload(fileSize: sizeName) {
                await self.downloadAttachment()
            })
        } else {
            await downloadAttachment()
        }
    }

    /// Downloads the attachment and presents the save file picker. The downloaded url is stored in
    /// the state so that the file isn't downloaded again if the user saves it more than once.
    ///
    private func downloadAttachment() async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.downloading))

            guard let temporaryUrl = try await services.vaultRepository.downloadAttachment(
                state.attachment,
                cipher: state.cipher,
            ) else {
                return coordinator.showAlert(.defaultAlert(title: Localizations.unableToDownloadFile))
            }

            state.temporaryUrl = temporaryUrl
            coordinator.hideLoadingOverlay()
            coordinator.navigate(to: .saveFile(temporaryUrl: temporaryUrl))
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.unableToDownloadFile))
            services.errorReporter.log(error: error)
        }
    }

    /// Writes the image content back to the temporary url if its file was deleted after the image
    /// was loaded into memory, so that it can be saved by the user. The file is removed again when
    /// this processor is deallocated.
    ///
    /// - Parameter temporaryUrl: The url where the downloaded file is stored.
    ///
    private func restoreTemporaryFileIfNeeded(at temporaryUrl: URL) throws {
        let data: Data
        switch state.content {
        case let .animatedImage(imageData), let .image(imageData):
            data = imageData
        case .fileError, .unsupportedFileType:
            return
        }

        guard !FileManager.default.fileExists(atPath: temporaryUrl.path) else { return }
        try FileManager.default.createDirectory(
            at: temporaryUrl.deletingLastPathComponent(),
            withIntermediateDirectories: true,
        )
        try data.write(to: temporaryUrl, options: .atomic)
    }

    /// Presents the save file picker for the downloaded file. Image content is first written back
    /// to the temporary url if needed.
    ///
    /// - Parameter temporaryUrl: The url where the downloaded file is stored.
    ///
    private func saveFile(at temporaryUrl: URL) {
        do {
            try restoreTemporaryFileIfNeeded(at: temporaryUrl)
            coordinator.navigate(to: .saveFile(temporaryUrl: temporaryUrl))
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.unableToDownloadFile))
            services.errorReporter.log(error: error)
        }
    }
}
