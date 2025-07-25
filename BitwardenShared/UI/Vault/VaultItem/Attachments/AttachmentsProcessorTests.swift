import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared

class AttachmentsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>!
    var errorReporter: MockErrorReporter!
    var subject: AttachmentsProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()

        subject = AttachmentsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                vaultRepository: vaultRepository
            ),
            state: AttachmentsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `fileSelectionCompleted()` updates the state with the new file values.
    @MainActor
    func test_fileSelectionCompleted() {
        let data = Data("data".utf8)
        subject.fileSelectionCompleted(fileName: "exampleFile.txt", data: data)
        XCTAssertEqual(subject.state.fileName, "exampleFile.txt")
        XCTAssertEqual(subject.state.fileData, data)
    }

    /// `perform(_:)` with `.loadPremiumStatus` loads the premium status and displays an alert if necessary.
    @MainActor
    func test_perform_loadPremiumStatus() async throws {
        vaultRepository.doesActiveAccountHavePremiumResult = false

        await subject.perform(.loadPremiumStatus)

        XCTAssertFalse(subject.state.hasPremium)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.premiumRequired))
    }

    /// `perform(_:)` with `.save` saves the attachment and updates the view.
    @MainActor
    func test_perform_save() async throws {
        subject.state.cipher = .fixture()
        subject.state.fileName = "only cool people can see this file.txt"
        subject.state.fileData = Data()
        subject.state.hasPremium = true

        await subject.perform(.save)

        XCTAssertEqual(vaultRepository.saveAttachmentFileName, "only cool people can see this file.txt")
        XCTAssertEqual(subject.state.cipher, .fixture())
        XCTAssertNil(subject.state.fileName)
        XCTAssertNil(subject.state.fileData)
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.attachementAdded))
    }

    /// `perform(_:)` with `.save` handles any errors.
    @MainActor
    func test_perform_save_error() async throws {
        subject.state.cipher = .fixture()
        subject.state.fileName = "only cool people can see this file.txt"
        subject.state.fileData = Data()
        subject.state.hasPremium = true
        vaultRepository.saveAttachmentResult = .failure(BitwardenTestError.example)

        await subject.perform(.save)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.save` displays an error if the user doesn't have premium.
    @MainActor
    func test_perform_save_noFile() async throws {
        subject.state.hasPremium = false

        await subject.perform(.save)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .inputValidationAlert(error: .init(message: Localizations.validationFieldRequired(Localizations.file)))
        )
    }

    /// `perform(_:)` with `.save` displays an error if the user doesn't have premium.
    @MainActor
    func test_perform_save_noPremium() async throws {
        subject.state.fileName = "only cool people can see this file.txt"
        subject.state.hasPremium = false

        await subject.perform(.save)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.premiumRequired
            )
        )
    }

    /// `perform(_:)` with `.save` shows an alert if the file is too large.
    @MainActor
    func test_perform_save_tooLarge() async throws {
        subject.state.fileName = "only cool people can see this file.txt"
        subject.state.fileData = Data(count: 104_857_601)
        subject.state.hasPremium = true

        await subject.perform(.save)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(title: Localizations.anErrorHasOccurred, message: Localizations.maxFileSize)
        )
    }

    /// `receive(_:)` with `.chooseFilePressed` navigates to the document browser.
    @MainActor
    func test_receive_chooseFilePressed() async throws {
        subject.receive(.chooseFilePressed)

        let alert = try XCTUnwrap(coordinator.alertShown.last)

        try await alert.tapAction(title: Localizations.browse)
        XCTAssertEqual(coordinator.routes.last, .fileSelection(.file))
        XCTAssertIdentical(coordinator.contexts.last as? FileSelectionDelegate, subject)

        try await alert.tapAction(title: Localizations.camera)
        XCTAssertEqual(coordinator.routes.last, .fileSelection(.camera))
        XCTAssertIdentical(coordinator.contexts.last as? FileSelectionDelegate, subject)

        try await alert.tapAction(title: Localizations.photos)
        XCTAssertEqual(coordinator.routes.last, .fileSelection(.photo))
        XCTAssertIdentical(coordinator.contexts.last as? FileSelectionDelegate, subject)
    }

    /// `.receive(_:)` with `.deletePressed(_)` presents the confirm alert and deletes the attachment.
    @MainActor
    func test_receive_deletePressed() async throws {
        subject.state.cipher = .fixture()

        subject.receive(.deletePressed(.fixture()))

        // Confirm on the alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.deleting)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(vaultRepository.deleteAttachmentId, "1")
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.attachmentDeleted))
    }

    /// `.receive(_:)` with `.deletePressed(_)` handles any errors.
    @MainActor
    func test_receive_deletePressed_error() async throws {
        subject.state.cipher = .fixture()
        vaultRepository.deleteAttachmentResult = .failure(BitwardenTestError.example)

        subject.receive(.deletePressed(.fixture()))

        // Confirm on the alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `.receive(_:)` with `.deletePressed(_)` throws an error if either element is missing its id.
    @MainActor
    func test_receive_deletePressed_noIdError() async throws {
        subject.state.cipher = .fixture(id: nil)

        subject.receive(.deletePressed(.fixture(id: nil)))

        // Confirm on the alert.
        let confirmAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await confirmAction.handler?(confirmAction, [])

        // Verify the results.
        XCTAssertEqual(coordinator.errorAlertsShown as? [CipherAPIServiceError], [.updateMissingId])
        XCTAssertEqual(errorReporter.errors.last as? CipherAPIServiceError, .updateMissingId)
    }

    /// `receive(_:)` with `.dismissPressed` dismisses the view.
    @MainActor
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)

        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    @MainActor
    func test_receive_toastShown() {
        let toast = Toast(title: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }
}
