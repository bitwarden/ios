import BitwardenKit
import BitwardenResources
import BitwardenSdk
import Foundation
import UIKit

/// A protocol for a helper to centralize downloading and previewing a vault item's attachment.
protocol AttachmentPreviewHelper { // sourcery: AutoMockable
    /// Downloads an attachment and shows the in-app preview screen for it.
    ///
    /// - Parameters:
    ///   - attachment: The attachment to preview.
    ///   - cipher: The cipher that owns the attachment.
    func showPreview(
        for attachment: AttachmentView,
        cipher: CipherView,
    ) async
}

/// The default implementation of `AttachmentPreviewHelper`.
@MainActor
class DefaultAttachmentPreviewHelper: AttachmentPreviewHelper {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>

    /// The services used by this helper.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `DefaultAttachmentPreviewHelper`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this helper.
    ///
    init(
        coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>,
        services: Services,
    ) {
        self.coordinator = coordinator
        self.services = services
    }

    // MARK: Methods

    func showPreview(
        for attachment: AttachmentView,
        cipher: CipherView,
    ) async {
        if let sizeName = attachment.sizeName,
           let size = Int(attachment.size ?? ""),
           size >= Constants.largeFileSize {
            coordinator.showAlert(.confirmDownload(fileSize: sizeName) {
                await self.downloadAndPreview(attachment, cipher: cipher)
            })
        } else {
            await downloadAndPreview(attachment, cipher: cipher)
        }
    }

    // MARK: Private Methods

    /// Classifies the downloaded file's content for display in the preview screen.
    ///
    /// - Parameter attachment: The attachment that was downloaded.
    /// - Parameter temporaryUrl: The url where the downloaded file is stored.
    /// - Returns: The content to show in the preview screen.
    private func classify(_ attachment: AttachmentView, temporaryUrl: URL) -> AttachmentPreviewContent {
        guard attachment.isImage else {
            return .unsupportedFileType(fileExtension: attachment.fileExtension ?? "")
        }
        guard let data = try? Data(contentsOf: temporaryUrl), UIImage(data: data) != nil else {
            return .fileError
        }
        return .image(data)
    }

    /// Downloads the attachment and navigates to the preview screen, classifying the downloaded
    /// content along the way.
    ///
    /// - Parameters:
    ///   - attachment: The attachment to download.
    ///   - cipher: The cipher that owns the attachment.
    private func downloadAndPreview(_ attachment: AttachmentView, cipher: CipherView) async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            coordinator.showLoadingOverlay(title: Localizations.openingPreview)

            guard let temporaryUrl = try await services.vaultRepository.downloadAttachment(
                attachment,
                cipher: cipher,
            ) else {
                return coordinator.showAlert(.defaultAlert(title: Localizations.unableToDownloadFile))
            }

            coordinator.hideLoadingOverlay()
            coordinator.navigate(to: .attachmentPreview(AttachmentPreviewState(
                attachment: attachment,
                content: classify(attachment, temporaryUrl: temporaryUrl),
                fileName: attachment.fileName ?? "",
                temporaryUrl: temporaryUrl,
            )))
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.unableToDownloadFile))
            services.errorReporter.log(error: error)
        }
    }
}
