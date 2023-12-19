import XCTest

@testable import BitwardenShared

// MARK: - AddEditSendItemProcessorTests

class AddEditSendItemProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SendRoute>!
    var subject: AddEditSendItemProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        subject = AddEditSendItemProcessor(
            coordinator: coordinator,
            state: AddEditSendItemState()
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.savePressed` saves the item.
    func test_perform_savePressed() async {
        await subject.perform(.savePressed)

        XCTAssertEqual(coordinator.loadingOverlaysShown, [
            LoadingOverlayState(title: Localizations.saving),
        ])
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
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

    /// `receive(_:)` with `.passwordVisibileChanged` updates the password visibility.
    func test_receive_passwordVisibleChanged() {
        subject.state.isPasswordVisible = false
        subject.receive(.passwordVisibileChanged(true))

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

    /// `receive(_:)` with `.typeChanged` updates the type.
    func test_receive_typeChanged() {
        subject.state.type = .text
        subject.receive(.typeChanged(.file))

        XCTAssertEqual(subject.state.type, .file)
    }
}
