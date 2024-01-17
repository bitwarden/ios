import XCTest

@testable import BitwardenShared

// MARK: - AddEditSendItemProcessorTests

class AddEditSendItemProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SendRoute>!
    var sendRepository: MockSendRepository!
    var subject: AddEditSendItemProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        sendRepository = MockSendRepository()
        subject = AddEditSendItemProcessor(
            coordinator: coordinator,
            services: ServiceContainer.withMocks(sendRepository: sendRepository),
            state: AddEditSendItemState()
        )
    }

    // MARK: Tests

    /// `fileSelectionCompleted()` updates the state with the new file values.
    func test_fileSelectionCompleted() {
        let data = Data("data".utf8)
        subject.fileSelectionCompleted(fileName: "exampleFile.txt", data: data)
        XCTAssertEqual(subject.state.fileName, "exampleFile.txt")
        XCTAssertEqual(subject.state.fileData, data)
    }

    /// `perform(_:)` with `.savePressed` and valid input saves the item.
    func test_perform_savePressed_validated_success() async {
        subject.state.name = "Name"
        subject.state.type = .text
        subject.state.text = "Text"
        subject.state.deletionDate = .custom
        subject.state.customDeletionDate = Date(year: 2023, month: 11, day: 5)
        sendRepository.addSendResult = .success(())

        await subject.perform(.savePressed)

        XCTAssertEqual(coordinator.loadingOverlaysShown, [
            LoadingOverlayState(title: Localizations.saving),
        ])
        XCTAssertEqual(sendRepository.addSendSendView?.name, "Name")
        XCTAssertEqual(sendRepository.addSendSendView?.text?.text, "Text")
        XCTAssertEqual(sendRepository.addSendSendView?.deletionDate, Date(year: 2023, month: 11, day: 5))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `perform(_:)` with `.savePressed` and valid input saves the item.
    func test_perform_savePressed_validated_error() async {
        subject.state.name = "Name"
        subject.state.type = .text
        subject.state.text = "Text"
        subject.state.deletionDate = .custom
        subject.state.customDeletionDate = Date(year: 2023, month: 11, day: 5)
        sendRepository.addSendResult = .failure(BitwardenTestError.example)

        await subject.perform(.savePressed)

        XCTAssertEqual(coordinator.loadingOverlaysShown, [
            LoadingOverlayState(title: Localizations.saving),
        ])
        XCTAssertEqual(sendRepository.addSendSendView?.name, "Name")
        XCTAssertEqual(sendRepository.addSendSendView?.text?.text, "Text")
        XCTAssertEqual(sendRepository.addSendSendView?.deletionDate, Date(year: 2023, month: 11, day: 5))

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
    }

    /// `perform(_:)` with `.savePressed` and valid input saves the item.
    func test_perform_savePressed_unvalidated() async {
        subject.state.name = ""
        await subject.perform(.savePressed)

        XCTAssertTrue(coordinator.loadingOverlaysShown.isEmpty)
        XCTAssertNil(sendRepository.addSendSendView)
        XCTAssertEqual(coordinator.alertShown, [
            .validationFieldRequired(fieldName: Localizations.name),
        ])
    }

    /// `receive(_:)` with `.chooseFilePressed` navigates to the document browser.
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

    /// `receive(_:)` with `.customDeletionDateChanged` updates the custom deletion date.
    func test_receive_customDeletionDateChanged() {
        subject.state.customDeletionDate = Date(year: 2000, month: 5, day: 5)
        subject.receive(.customDeletionDateChanged(Date(year: 2023, month: 11, day: 5)))

        XCTAssertEqual(subject.state.customDeletionDate, Date(year: 2023, month: 11, day: 5))
    }

    /// `receive(_:)` with `.customExpirationDateChanged` updates the custom expiration date.
    func test_receive_customExpirationDateChanged() {
        subject.state.customExpirationDate = Date(year: 2000, month: 5, day: 5)
        subject.receive(.customExpirationDateChanged(Date(year: 2023, month: 11, day: 5)))

        XCTAssertEqual(subject.state.customExpirationDate, Date(year: 2023, month: 11, day: 5))
    }

    /// `receive(_:)` with `.deactivateThisSendChanged` updates the deactivate this send toggle.
    func test_receive_deactivateThisSendChanged() {
        subject.state.isDeactivateThisSendOn = false
        subject.receive(.deactivateThisSendChanged(true))

        XCTAssertTrue(subject.state.isDeactivateThisSendOn)
    }

    /// `receive(_:)` with `.deletionDateChanged` updates the deletion date.
    func test_receive_deletionDateChanged() {
        subject.state.deletionDate = .sevenDays
        subject.receive(.deletionDateChanged(.thirtyDays))

        XCTAssertEqual(subject.state.deletionDate, .thirtyDays)
    }

    /// `receive(_:)` with `.dismissPressed` navigates to the dismiss route.
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.expirationDateChanged` updates the expiration date.
    func test_receive_expirationDateChanged() {
        subject.state.expirationDate = .sevenDays
        subject.receive(.expirationDateChanged(.thirtyDays))

        XCTAssertEqual(subject.state.expirationDate, .thirtyDays)
    }

    /// `receive(_:)` with `.hideMyEmailChanged` updates the hide my email toggle.
    func test_receive_hideMyEmailChanged() {
        subject.state.isHideMyEmailOn = false
        subject.receive(.hideMyEmailChanged(true))

        XCTAssertTrue(subject.state.isHideMyEmailOn)
    }

    /// `receive(_:)` with `.hideTextByDefaultChanged` updates the hide text by default toggle.
    func test_receive_hideTextByDefaultChanged() {
        subject.state.isHideTextByDefaultOn = false
        subject.receive(.hideTextByDefaultChanged(true))

        XCTAssertTrue(subject.state.isHideTextByDefaultOn)
    }

    /// `receive(_:)` with `.maximumAccessCountChanged` updates the maximum access count.
    func test_receive_maximumAccessCountChanged() {
        subject.state.maximumAccessCount = 0
        subject.receive(.maximumAccessCountChanged(42))

        XCTAssertEqual(subject.state.maximumAccessCount, 42)
    }

    /// `receive(_:)` with `.nameChanged` updates the name.
    func test_receive_nameChanged() {
        subject.state.name = ""
        subject.receive(.nameChanged("Name"))

        XCTAssertEqual(subject.state.name, "Name")
    }

    /// `receive(_:)` with `.notesChanged` updates the notes.
    func test_receive_notesChanged() {
        subject.state.notes = ""
        subject.receive(.notesChanged("Notes"))

        XCTAssertEqual(subject.state.notes, "Notes")
    }

    /// `receive(_:)` with `.optionsPressed` expands and collapses the options.
    func test_receive_optionsPressed() {
        subject.state.isOptionsExpanded = false
        subject.receive(.optionsPressed)
        XCTAssertTrue(subject.state.isOptionsExpanded)

        subject.receive(.optionsPressed)
        XCTAssertFalse(subject.state.isOptionsExpanded)
    }

    /// `receive(_:)` with `.passwordChanged` updates the password.
    func test_receive_passwordChanged() {
        subject.state.password = ""
        subject.receive(.passwordChanged("password"))

        XCTAssertEqual(subject.state.password, "password")
    }

    /// `receive(_:)` with `.passwordVisibleChanged` updates the password visibility.
    func test_receive_passwordVisibleChanged() {
        subject.state.isPasswordVisible = false
        subject.receive(.passwordVisibleChanged(true))

        XCTAssertTrue(subject.state.isPasswordVisible)
    }

    /// `receive(_:)` with `.shareOnSaveChanged` updates the share on save toggle.
    func test_receive_shareOnSaveChanged() {
        subject.state.isShareOnSaveOn = false
        subject.receive(.shareOnSaveChanged(true))

        XCTAssertTrue(subject.state.isShareOnSaveOn)
    }

    /// `receive(_:)` with `.textChanged` updates the text.
    func test_receive_textChanged() {
        subject.state.text = ""
        subject.receive(.textChanged("Text"))

        XCTAssertEqual(subject.state.text, "Text")
    }

    /// `receive(_:)` with `.typeChanged` and premium access updates the type.
    func test_receive_typeChanged_hasPremium() {
        subject.state.hasPremium = true
        subject.state.type = .text
        subject.receive(.typeChanged(.file))

        XCTAssertEqual(subject.state.type, .file)
    }

    /// `receive(_:)` with `.typeChanged` and no premium access does not update the type.
    func test_receive_typeChanged_notHasPremium() {
        subject.state.hasPremium = false
        subject.state.type = .text
        subject.receive(.typeChanged(.file))

        XCTAssertEqual(coordinator.alertShown, [
            .defaultAlert(title: Localizations.sendFilePremiumRequired),
        ])
        XCTAssertEqual(subject.state.type, .text)
    }
}
