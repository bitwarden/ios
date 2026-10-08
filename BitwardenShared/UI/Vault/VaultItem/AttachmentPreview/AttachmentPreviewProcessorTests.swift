import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared

// MARK: - AttachmentPreviewProcessorTests

@MainActor
struct AttachmentPreviewProcessorTests {
    // MARK: Properties

    let coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>
    let errorReporter: MockErrorReporter
    let temporaryUrl = URL(fileURLWithPath: "/tmp/photo.png")
    let vaultRepository: MockVaultRepository
    let subject: AttachmentPreviewProcessor

    // MARK: Initialization

    init() {
        coordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()
        subject = AttachmentPreviewProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(errorReporter: errorReporter, vaultRepository: vaultRepository),
            state: AttachmentPreviewState(
                attachment: .fixture(fileName: "photo.png"),
                cipher: .loginFixture(),
                content: .image(Data()),
                fileName: "photo.png",
                temporaryUrl: temporaryUrl,
            ),
        )
    }

    // MARK: Tests

    /// `receive(_:)` with `.dismissPressed` navigates to `.dismiss()`.
    @Test
    func receive_dismissPressed() {
        subject.receive(.dismissPressed)
        #expect(coordinator.routes.last == .dismiss())
    }

    /// `perform(_:)` with `.downloadPressed` navigates to `.saveFile(temporaryUrl:)` with the
    /// state's temporary url.
    @Test
    func perform_downloadPressed() async {
        await subject.perform(.downloadPressed)
        #expect(coordinator.routes.last == .saveFile(temporaryUrl: temporaryUrl))
    }

    /// `perform(_:)` with `.downloadPressed` writes image content back to the temporary url if the
    /// file was deleted after the image was loaded, before navigating to `.saveFile`.
    @Test(arguments: [true, false])
    func perform_downloadPressed_restoresDeletedFile(isAnimated: Bool) async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("photo.png")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let data = Data("image data".utf8)
        let subject = makeSubject(content: isAnimated ? .animatedImage(data) : .image(data), temporaryUrl: url)

        await subject.perform(.downloadPressed)

        #expect(try Data(contentsOf: url) == data)
        #expect(coordinator.routes.last == .saveFile(temporaryUrl: url))
    }

    /// `perform(_:)` with `.downloadPressed` doesn't overwrite a file that still exists.
    @Test
    func perform_downloadPressed_existingFile() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("existing".utf8).write(to: url)
        let subject = makeSubject(content: .image(Data("image data".utf8)), temporaryUrl: url)

        await subject.perform(.downloadPressed)

        #expect(try Data(contentsOf: url) == Data("existing".utf8))
        #expect(coordinator.routes.last == .saveFile(temporaryUrl: url))
    }

    /// `perform(_:)` with `.downloadPressed` saves a non-image file from its existing download without
    /// downloading it again, and doesn't write a file for that content.
    @Test(arguments: [AttachmentPreviewContent.fileError, .unsupportedFileType(fileExtension: "pdf")])
    func perform_downloadPressed_nonImageContent(content: AttachmentPreviewContent) async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("file".utf8).write(to: url)
        let subject = makeSubject(content: content, temporaryUrl: url)

        await subject.perform(.downloadPressed)

        #expect(vaultRepository.downloadAttachmentAttachment == nil)
        #expect(try Data(contentsOf: url) == Data("file".utf8))
        #expect(coordinator.routes.last == .saveFile(temporaryUrl: url))
    }

    /// `perform(_:)` with `.downloadPressed` downloads a non-image file again when its downloaded
    /// file no longer exists, for example because the export picker moved it after it was saved.
    @Test(arguments: [AttachmentPreviewContent.fileError, .unsupportedFileType(fileExtension: "pdf")])
    func perform_downloadPressed_nonImageContent_fileMoved(content: AttachmentPreviewContent) async {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let downloadUrl = URL(fileURLWithPath: "/tmp/\(UUID().uuidString).pdf")
        vaultRepository.downloadAttachmentResult = .success(downloadUrl)
        let subject = makeSubject(content: content, temporaryUrl: url)

        await subject.perform(.downloadPressed)

        #expect(vaultRepository.downloadAttachmentAttachment == .fixture(fileName: "photo.png"))
        #expect(subject.state.temporaryUrl == downloadUrl)
        #expect(coordinator.routes.last == .saveFile(temporaryUrl: downloadUrl))
    }

    /// `perform(_:)` with `.downloadPressed` asks the user to confirm before downloading a large image
    /// that is too large to preview, and only downloads it once the user confirms.
    @Test
    func perform_downloadPressed_fileTooLarge_largeFileConfirm() async throws {
        let downloadUrl = URL(fileURLWithPath: "/tmp/photo.png")
        let attachment = AttachmentView.fixture(fileName: "photo.png", size: "11000000", sizeName: "big")
        vaultRepository.downloadAttachmentResult = .success(downloadUrl)
        let subject = makeSubject(attachment: attachment, content: .fileTooLarge, temporaryUrl: nil)

        await subject.perform(.downloadPressed)

        let alert = try #require(coordinator.alertShown.last)
        #expect(alert.title == Localizations.attachmentLargeWarning("big"))
        #expect(vaultRepository.downloadAttachmentAttachment == nil)

        try await alert.tapAction(title: Localizations.yes)

        #expect(vaultRepository.downloadAttachmentAttachment == attachment)
        #expect(coordinator.routes.last == .saveFile(temporaryUrl: downloadUrl))
    }

    /// `perform(_:)` with `.downloadPressed` shows an alert and logs the error if the image data
    /// can't be written back to the temporary url.
    @Test
    func perform_downloadPressed_writeError() async throws {
        // A file is used as the parent "directory" so that creating the directory fails.
        let blockingFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: blockingFile) }
        try Data().write(to: blockingFile)
        let url = blockingFile.appendingPathComponent("photo.png")
        let subject = makeSubject(content: .image(Data("image data".utf8)), temporaryUrl: url)

        await subject.perform(.downloadPressed)

        #expect(coordinator.alertShown.last == .defaultAlert(title: Localizations.unableToDownloadFile))
        #expect(coordinator.routes.isEmpty)
        #expect(errorReporter.errors.count == 1)
    }

    /// `perform(_:)` with `.downloadPressed` downloads a file that can't be previewed, stores its
    /// url in the state, and navigates to `.saveFile(temporaryUrl:)`.
    @Test
    func perform_downloadPressed_unsupportedFile() async {
        let downloadUrl = URL(fileURLWithPath: "/tmp/statement.pdf")
        let attachment = AttachmentView.fixture(fileName: "statement.pdf")
        let cipher = CipherView.loginFixture()
        vaultRepository.downloadAttachmentResult = .success(downloadUrl)
        let subject = makeSubject(
            attachment: attachment,
            cipher: cipher,
            content: .unsupportedFileType(fileExtension: "pdf"),
            temporaryUrl: nil,
        )

        await subject.perform(.downloadPressed)

        #expect(vaultRepository.downloadAttachmentAttachment == attachment)
        #expect(vaultRepository.downloadAttachmentCipher == cipher)
        #expect(subject.state.temporaryUrl == downloadUrl)
        #expect(coordinator.routes.last == .saveFile(temporaryUrl: downloadUrl))
    }

    /// `perform(_:)` with `.downloadPressed` doesn't download a large file that can't be previewed
    /// if the user cancels the confirmation alert.
    @Test
    func perform_downloadPressed_unsupportedFile_largeFileCancel() async throws {
        let attachment = AttachmentView.fixture(fileName: "archive.zip", size: "11000000", sizeName: "big")
        let subject = makeSubject(
            attachment: attachment,
            content: .unsupportedFileType(fileExtension: "zip"),
            temporaryUrl: nil,
        )

        await subject.perform(.downloadPressed)

        let alert = try #require(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.no)

        #expect(vaultRepository.downloadAttachmentAttachment == nil)
        #expect(coordinator.routes.isEmpty)
        #expect(subject.state.temporaryUrl == nil)
    }

    /// `perform(_:)` with `.downloadPressed` asks the user to confirm before downloading a large file
    /// that can't be previewed, and only downloads it once the user confirms.
    @Test
    func perform_downloadPressed_unsupportedFile_largeFileConfirm() async throws {
        let downloadUrl = URL(fileURLWithPath: "/tmp/archive.zip")
        let attachment = AttachmentView.fixture(fileName: "archive.zip", size: "11000000", sizeName: "big")
        vaultRepository.downloadAttachmentResult = .success(downloadUrl)
        let subject = makeSubject(
            attachment: attachment,
            content: .unsupportedFileType(fileExtension: "zip"),
            temporaryUrl: nil,
        )

        await subject.perform(.downloadPressed)

        let alert = try #require(coordinator.alertShown.last)
        #expect(alert.title == Localizations.attachmentLargeWarning("big"))
        #expect(vaultRepository.downloadAttachmentAttachment == nil)

        try await alert.tapAction(title: Localizations.yes)

        #expect(vaultRepository.downloadAttachmentAttachment == attachment)
        #expect(coordinator.routes.last == .saveFile(temporaryUrl: downloadUrl))
    }

    /// `perform(_:)` with `.downloadPressed` shows an alert and logs the error if downloading a file
    /// that can't be previewed throws.
    @Test
    func perform_downloadPressed_unsupportedFile_downloadError() async {
        vaultRepository.downloadAttachmentResult = .failure(BitwardenTestError.example)
        let subject = makeSubject(content: .unsupportedFileType(fileExtension: "pdf"), temporaryUrl: nil)

        await subject.perform(.downloadPressed)

        #expect(coordinator.alertShown.last == .defaultAlert(title: Localizations.unableToDownloadFile))
        #expect(coordinator.routes.isEmpty)
        #expect(subject.state.temporaryUrl == nil)
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    /// `perform(_:)` with `.downloadPressed` shows an alert and doesn't navigate if downloading a file
    /// that can't be previewed returns no url.
    @Test
    func perform_downloadPressed_unsupportedFile_nilUrl() async {
        vaultRepository.downloadAttachmentResult = .success(nil)
        let subject = makeSubject(content: .unsupportedFileType(fileExtension: "pdf"), temporaryUrl: nil)

        await subject.perform(.downloadPressed)

        #expect(coordinator.alertShown.last == .defaultAlert(title: Localizations.unableToDownloadFile))
        #expect(coordinator.routes.isEmpty)
        #expect(subject.state.temporaryUrl == nil)
    }

    /// The processor clears any temporary downloads when it's deallocated.
    @Test
    func deinit_clearsTemporaryDownloads() {
        var localSubject: AttachmentPreviewProcessor? = AttachmentPreviewProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(vaultRepository: vaultRepository),
            state: AttachmentPreviewState(
                attachment: .fixture(fileName: "photo.png"),
                cipher: .loginFixture(),
                content: .image(Data()),
                fileName: "photo.png",
                temporaryUrl: temporaryUrl,
            ),
        )
        _ = localSubject

        #expect(!vaultRepository.clearTemporaryDownloadsCalled)
        localSubject = nil

        #expect(vaultRepository.clearTemporaryDownloadsCalled)
    }

    // MARK: Private Methods

    /// Creates a processor for the given attachment, cipher, content, and temporary url.
    private func makeSubject(
        attachment: AttachmentView = .fixture(fileName: "photo.png"),
        cipher: CipherView = .loginFixture(),
        content: AttachmentPreviewContent,
        temporaryUrl: URL?,
    ) -> AttachmentPreviewProcessor {
        AttachmentPreviewProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(errorReporter: errorReporter, vaultRepository: vaultRepository),
            state: AttachmentPreviewState(
                attachment: attachment,
                cipher: cipher,
                content: content,
                fileName: attachment.fileName ?? "",
                temporaryUrl: temporaryUrl,
            ),
        )
    }
}
