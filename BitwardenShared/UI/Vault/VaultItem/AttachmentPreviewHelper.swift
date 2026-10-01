import BitwardenKit
import BitwardenResources
import BitwardenSdk
import Foundation
import ImageIO
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

    /// Classifies the downloaded file's content for display in the preview screen. Reading and
    /// decoding the file is done off the main actor since attachments can be large.
    ///
    /// - Parameter attachment: The attachment that was downloaded.
    /// - Parameter temporaryUrl: The url where the downloaded file is stored.
    /// - Returns: The content to show in the preview screen.
    private func classify(_ attachment: AttachmentView, temporaryUrl: URL) async -> AttachmentPreviewContent {
        let fileExtension = attachment.fileExtension ?? ""
        let isGif = attachment.isGif
        let isImage = attachment.isImage
        return await Task.detached {
            classifyDownloadedFile(
                fileExtension: fileExtension,
                isGif: isGif,
                isImage: isImage,
                temporaryUrl: temporaryUrl,
            )
        }.value
    }

    /// Deletes the decrypted temporary file once its image content has been loaded into memory, so
    /// it isn't left on disk while the preview is displayed. The preview screen writes the file
    /// back out from memory only if the user chooses to download it. Content that couldn't be
    /// loaded into memory keeps its file so that it can still be downloaded.
    ///
    /// - Parameters:
    ///   - content: The classified content of the downloaded file.
    ///   - temporaryUrl: The url where the downloaded file is stored.
    private func deleteTemporaryFileIfLoaded(_ content: AttachmentPreviewContent, at temporaryUrl: URL) {
        switch content {
        case .animatedImage, .image:
            do {
                try FileManager.default.removeItem(at: temporaryUrl)
            } catch {
                services.errorReporter.log(error: error)
            }
        case .fileError, .unsupportedFileType:
            break
        }
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

            let content = await classify(attachment, temporaryUrl: temporaryUrl)
            deleteTemporaryFileIfLoaded(content, at: temporaryUrl)

            coordinator.hideLoadingOverlay()
            coordinator.navigate(to: .attachmentPreview(AttachmentPreviewState(
                attachment: attachment,
                content: content,
                fileName: attachment.fileName ?? "",
                temporaryUrl: temporaryUrl,
            )))
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.unableToDownloadFile))
            services.errorReporter.log(error: error)
        }
    }
}

// MARK: - Private

/// Classifies a downloaded file's content for display in the preview screen. This reads and decodes
/// the file synchronously, so it should be called off the main actor.
///
/// - Parameters:
///   - fileExtension: The attachment's file extension.
///   - isGif: Whether the attachment has a GIF file extension.
///   - isImage: Whether the attachment has an image file extension.
///   - temporaryUrl: The url where the downloaded file is stored.
/// - Returns: The content to show in the preview screen.
private nonisolated func classifyDownloadedFile(
    fileExtension: String,
    isGif: Bool,
    isImage: Bool,
    temporaryUrl: URL,
) -> AttachmentPreviewContent {
    guard isImage else {
        return .unsupportedFileType(fileExtension: fileExtension)
    }
    guard let data = try? Data(contentsOf: temporaryUrl), UIImage(data: data) != nil else {
        return .fileError
    }
    if isGif,
       let source = CGImageSourceCreateWithData(data as CFData, nil),
       CGImageSourceGetCount(source) > 1 {
        return .animatedImage(data)
    }
    return .image(data)
}
