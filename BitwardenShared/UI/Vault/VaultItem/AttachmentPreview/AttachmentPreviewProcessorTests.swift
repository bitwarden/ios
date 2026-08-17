import BitwardenKit
import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared

// MARK: - AttachmentPreviewProcessorTests

@MainActor
struct AttachmentPreviewProcessorTests {
    // MARK: Properties

    let coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>
    let temporaryUrl = URL(fileURLWithPath: "/tmp/photo.png")
    let vaultRepository: MockVaultRepository
    let subject: AttachmentPreviewProcessor

    // MARK: Initialization

    init() {
        coordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()
        vaultRepository = MockVaultRepository()
        subject = AttachmentPreviewProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(vaultRepository: vaultRepository),
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
}
