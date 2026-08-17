import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import Foundation
import TestHelpers
import Testing
import UIKit

@testable import BitwardenShared

// MARK: - AttachmentPreviewHelperTests

@MainActor
struct AttachmentPreviewHelperTests {
    // MARK: Properties

    let coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>
    let errorReporter: MockErrorReporter
    let vaultRepository: MockVaultRepository
    let subject: AttachmentPreviewHelper

    // MARK: Initialization

    init() {
        coordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()
        subject = DefaultAttachmentPreviewHelper(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                vaultRepository: vaultRepository,
            ),
        )
    }

    // MARK: Tests

    /// `showPreview(for:cipher:)` shows a confirmation alert before downloading a large attachment
    /// and only downloads once the user confirms.
    @Test
    func showPreview_largeFile_confirmation() async throws {
        let attachment = AttachmentView.fixture(fileName: "photo.png", size: "11000000", sizeName: "big")
        let cipher = CipherView.loginFixture()

        await subject.showPreview(for: attachment, cipher: cipher)

        let alert = try #require(coordinator.alertShown.last)
        #expect(alert.title == Localizations.attachmentLargeWarning("big"))
        #expect(vaultRepository.downloadAttachmentAttachment == nil)

        vaultRepository.downloadAttachmentResult = try .success(writeTemporaryImage())
        try await alert.tapAction(title: Localizations.yes)

        #expect(vaultRepository.downloadAttachmentAttachment == attachment)
        guard case .attachmentPreview = coordinator.routes.last else {
            Issue.record("Expected a navigation to .attachmentPreview")
            return
        }
    }

    /// `showPreview(for:cipher:)` doesn't download a large attachment if the user cancels the
    /// confirmation alert.
    @Test
    func showPreview_largeFile_cancel() async throws {
        let attachment = AttachmentView.fixture(fileName: "photo.png", size: "11000000", sizeName: "big")
        let cipher = CipherView.loginFixture()

        await subject.showPreview(for: attachment, cipher: cipher)

        let alert = try #require(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.no)

        #expect(vaultRepository.downloadAttachmentAttachment == nil)
        #expect(coordinator.routes.isEmpty)
    }

    /// `showPreview(for:cipher:)` skips the confirmation alert for small attachments.
    @Test
    func showPreview_smallFile() async throws {
        let attachment = AttachmentView.fixture(fileName: "photo.png", size: "10", sizeName: "small")
        let cipher = CipherView.loginFixture()
        vaultRepository.downloadAttachmentResult = try .success(writeTemporaryImage())

        await subject.showPreview(for: attachment, cipher: cipher)

        #expect(coordinator.alertShown.isEmpty)
        #expect(vaultRepository.downloadAttachmentAttachment == attachment)
    }

    /// `showPreview(for:cipher:)` navigates to the preview screen with `.image(data)` content when
    /// the attachment is an image that decodes successfully.
    @Test
    func showPreview_image_success() async throws {
        let attachment = AttachmentView.fixture(fileName: "photo.png", size: "10", sizeName: "small")
        let cipher = CipherView.loginFixture()
        let temporaryUrl = try writeTemporaryImage()
        vaultRepository.downloadAttachmentResult = .success(temporaryUrl)

        await subject.showPreview(for: attachment, cipher: cipher)

        guard case let .attachmentPreview(state) = coordinator.routes.last else {
            Issue.record("Expected a navigation to .attachmentPreview")
            return
        }
        guard case let .image(data) = state.content else {
            Issue.record("Expected .image content")
            return
        }
        #expect(!data.isEmpty)
        #expect(state.attachment == attachment)
        #expect(state.temporaryUrl == temporaryUrl)
        #expect(!coordinator.isLoadingOverlayShowing)
        #expect(coordinator.loadingOverlaysShown.last?.title == Localizations.openingPreview)
    }

    /// `showPreview(for:cipher:)` navigates to the preview screen with `.fileError` content when
    /// the downloaded image data can't be decoded.
    @Test
    func showPreview_image_corruptData() async throws {
        let attachment = AttachmentView.fixture(fileName: "photo.png", size: "10", sizeName: "small")
        let cipher = CipherView.loginFixture()
        let temporaryUrl = try writeTemporaryFile(data: Data("not an image".utf8))
        vaultRepository.downloadAttachmentResult = .success(temporaryUrl)

        await subject.showPreview(for: attachment, cipher: cipher)

        guard case let .attachmentPreview(state) = coordinator.routes.last else {
            Issue.record("Expected a navigation to .attachmentPreview")
            return
        }
        #expect(state.content == .fileError)
    }

    /// `showPreview(for:cipher:)` navigates to the preview screen with `.unsupportedFileType`
    /// content for a non-image attachment, without attempting to read/decode its data.
    @Test
    func showPreview_nonImage() async throws {
        let attachment = AttachmentView.fixture(fileName: "statement.pdf", size: "10", sizeName: "small")
        let cipher = CipherView.loginFixture()
        let temporaryUrl = try writeTemporaryFile(data: Data("%PDF-1.4".utf8))
        vaultRepository.downloadAttachmentResult = .success(temporaryUrl)

        await subject.showPreview(for: attachment, cipher: cipher)

        guard case let .attachmentPreview(state) = coordinator.routes.last else {
            Issue.record("Expected a navigation to .attachmentPreview")
            return
        }
        #expect(state.content == .unsupportedFileType(fileExtension: "pdf"))
    }

    /// `showPreview(for:cipher:)` shows the existing blocking alert and doesn't navigate when the
    /// download returns no url.
    @Test
    func showPreview_download_nilUrl() async throws {
        let attachment = AttachmentView.fixture(fileName: "photo.png", size: "10", sizeName: "small")
        let cipher = CipherView.loginFixture()
        vaultRepository.downloadAttachmentResult = .success(nil)

        await subject.showPreview(for: attachment, cipher: cipher)

        #expect(coordinator.alertShown.last == .defaultAlert(title: Localizations.unableToDownloadFile))
        #expect(coordinator.routes.isEmpty)
    }

    /// `showPreview(for:cipher:)` shows the existing blocking alert and doesn't navigate when the
    /// download throws.
    @Test
    func showPreview_download_error() async throws {
        let attachment = AttachmentView.fixture(fileName: "photo.png", size: "10", sizeName: "small")
        let cipher = CipherView.loginFixture()
        vaultRepository.downloadAttachmentResult = .failure(BitwardenTestError.example)

        await subject.showPreview(for: attachment, cipher: cipher)

        #expect(coordinator.alertShown.last == .defaultAlert(title: Localizations.unableToDownloadFile))
        #expect(coordinator.routes.isEmpty)
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    // MARK: Private Methods

    /// Writes valid image data to a temporary file and returns its url.
    private func writeTemporaryImage() throws -> URL {
        let data = try #require(UIImage(systemName: "photo")?.pngData())
        return try writeTemporaryFile(data: data)
    }

    /// Writes the given data to a temporary file and returns its url.
    private func writeTemporaryFile(data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try data.write(to: url)
        return url
    }
}
