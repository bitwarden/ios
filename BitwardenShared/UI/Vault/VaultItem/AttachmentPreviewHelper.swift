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
    ///   - handleNavigateToPremiumUpgrade: A closure called to navigate to the Premium upgrade flow.
    func showPreview(
        for attachment: AttachmentView,
        cipher: CipherView,
        handleNavigateToPremiumUpgrade: @escaping () async -> Void,
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
        handleNavigateToPremiumUpgrade: @escaping () async -> Void,
    ) async {
        // Files that can't be previewed aren't downloaded here. The preview screen shows its
        // unsupported or too large state right away, and the file is only downloaded if the user
        // taps Download.
        guard attachment.isImage, !attachment.isLargeFile else {
            let content: AttachmentPreviewContent = attachment.isImage
                ? .fileTooLarge
                : .unsupportedFileType(fileExtension: attachment.fileExtension ?? "")
            coordinator.navigate(to: .attachmentPreview(AttachmentPreviewState(
                attachment: attachment,
                cipher: cipher,
                content: content,
                fileName: attachment.fileName ?? "",
                temporaryUrl: nil,
            )))
            return
        }

        await downloadAndPreview(attachment, cipher: cipher)
    }

    // MARK: Private Methods

    /// Classifies the downloaded image's content for display in the preview screen. Reading and
    /// decoding the file is done off the main actor since attachments can be large.
    ///
    /// - Parameter attachment: The image attachment that was downloaded.
    /// - Parameter temporaryUrl: The url where the downloaded file is stored.
    /// - Returns: The content to show in the preview screen.
    private func classify(_ attachment: AttachmentView, temporaryUrl: URL) async -> AttachmentPreviewContent {
        let isGif = attachment.isGif
        return await Task.detached {
            classifyDownloadedFile(isGif: isGif, temporaryUrl: temporaryUrl)
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
        case .fileError, .fileTooLarge, .unsupportedFileType:
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
                cipher: cipher,
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

/// Classifies a downloaded image's content for display in the preview screen. This reads and decodes
/// the file synchronously, so it should be called off the main actor.
///
/// - Parameters:
///   - isGif: Whether the attachment has a GIF file extension.
///   - temporaryUrl: The url where the downloaded file is stored.
/// - Returns: The content to show in the preview screen.
private nonisolated func classifyDownloadedFile(
    isGif: Bool,
    temporaryUrl: URL,
) -> AttachmentPreviewContent {
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
