import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
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

    /// `receive(_:)` with `.toastShown` updates the state's toast.
    @Test
    func receive_toastShown() {
        let toast = Toast(title: "toast")
        subject.receive(.toastShown(toast))
        #expect(subject.state.toast == toast)

        subject.receive(.toastShown(nil))
        #expect(subject.state.toast == nil)
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

    /// `perform(_:)` with `.downloadPressed` doesn't write a file for content that keeps its
    /// downloaded file, and navigates to `.saveFile`.
    @Test(arguments: [AttachmentPreviewContent.fileError, .unsupportedFileType(fileExtension: "pdf")])
    func perform_downloadPressed_nonImageContent(content: AttachmentPreviewContent) async {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let subject = makeSubject(content: content, temporaryUrl: url)

        await subject.perform(.downloadPressed)

        #expect(!FileManager.default.fileExists(atPath: url.path))
        #expect(coordinator.routes.last == .saveFile(temporaryUrl: url))
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

    /// The processor clears any temporary downloads when it's deallocated.
    @Test
    func deinit_clearsTemporaryDownloads() {
        var localSubject: AttachmentPreviewProcessor? = AttachmentPreviewProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(vaultRepository: vaultRepository),
            state: AttachmentPreviewState(
                attachment: .fixture(fileName: "photo.png"),
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

    /// Creates a processor for the given content and temporary url.
    private func makeSubject(content: AttachmentPreviewContent, temporaryUrl: URL) -> AttachmentPreviewProcessor {
        AttachmentPreviewProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(errorReporter: errorReporter, vaultRepository: vaultRepository),
            state: AttachmentPreviewState(
                attachment: .fixture(fileName: "photo.png"),
                content: content,
                fileName: "photo.png",
                temporaryUrl: temporaryUrl,
            ),
        )
    }
}
