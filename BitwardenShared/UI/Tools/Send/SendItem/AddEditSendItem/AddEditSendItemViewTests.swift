import BitwardenResources
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - AddEditSendItemViewTests

class AddEditSendItemViewTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var processor: MockProcessor<AddEditSendItemState, AddEditSendItemAction, AddEditSendItemEffect>!
    var subject: AddEditSendItemView!

    /// A deletion date to use within the tests.
    let deletionDate = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41)

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: AddEditSendItemState())
        subject = AddEditSendItemView(store: Store(processor: processor))
    }

    // MARK: Tests

    /// Tapping the cancel button sends the `.dismissPressed` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the choose file button sends the `.chooseFilePressed` action.
    @MainActor
    func test_chooseFileButton_tap() throws {
        processor.state.type = .file
        let button = try subject.inspect().find(button: Localizations.chooseFile)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .chooseFilePressed)
    }

    /// Updating the deletion date menu sends the `.deletionDateChanged` action.
    @MainActor
    func test_deletionDateMenu_updated() throws {
        processor.state.isOptionsExpanded = true
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.deletionDate)
        try menuField.select(newValue: SendDeletionDateType.thirtyDays)
        XCTAssertEqual(processor.dispatchedActions.last, .deletionDateChanged(.thirtyDays))
    }

    /// Updating the maximum access count stepper sends the `.maximumAccessCountChanged` action.
    @MainActor
    func test_maximumAccessCountStepper_updated() throws {
        processor.state.isOptionsExpanded = true
        processor.state.maximumAccessCount = 42
        let stepper = try subject.inspect().find(
            BitwardenStepperType.self,
            containing: Localizations.maximumAccessCount
        )

        try stepper.increment()
        XCTAssertEqual(processor.dispatchedActions.last, .maximumAccessCountStepperChanged(43))

        try stepper.decrement()
        XCTAssertEqual(processor.dispatchedActions.last, .maximumAccessCountStepperChanged(41))
    }

    /// Updating the name textfield sends the `.nameChanged` action.
    @MainActor
    func test_nameTextField_updated() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.sendNameRequired)
        try textField.inputBinding().wrappedValue = "Name"
        XCTAssertEqual(processor.dispatchedActions.last, .nameChanged("Name"))
    }

    /// Updating the new password textfield sends the `.passwordChanged` action.
    @MainActor
    func test_newPasswordTextField_updated() throws {
        processor.state.isOptionsExpanded = true
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.newPassword)
        try textField.inputBinding().wrappedValue = "password"
        XCTAssertEqual(processor.dispatchedActions.last, .passwordChanged("password"))
    }

    /// Updating the notes textfield sends the `.notesChanged` action.
    @MainActor
    func test_notesTextField_updated() throws {
        processor.state.isOptionsExpanded = true
        let textField = try subject.inspect().find(
            type: BitwardenUITextViewType.self,
            accessibilityLabel: Localizations.privateNote
        )
        try textField.inputBinding().wrappedValue = "Notes"
        XCTAssertEqual(processor.dispatchedActions.last, .notesChanged("Notes"))
    }

    /// Updating the max access count textfield sends the `.maximumAccessCountChanged` action.
    @MainActor
    func test_maxAccessCountTextField_updated() throws {
        processor.state.isOptionsExpanded = true
        let textField = try subject.inspect()
            .find(viewWithAccessibilityIdentifier: "MaxAccessCountTextField")
            .textField()
        try textField.setInput("42")
        XCTAssertEqual(processor.dispatchedActions.last, .maximumAccessCountStepperChanged(42))
    }

    /// Tapping the options button sends the `.optionsPressed` action.
    @MainActor
    func test_optionsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.additionalOptions)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .optionsPressed)
    }

    /// Tapping the save button performs the `.savePressed` effect.
    @MainActor
    func test_saveButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .savePressed)
    }

    /// Setting `isSendDisabled` disables the controls within the view.
    @MainActor
    func test_sendDisabled() async throws {
        processor.state.isSendDisabled = true

        let infoContainer = try subject.inspect().find(InfoContainer<Text>.self)
        try XCTAssertEqual(infoContainer.text().string(), Localizations.sendDisabledWarning)

        let saveButton = try subject.inspect().find(asyncButton: Localizations.save)
        XCTAssertTrue(saveButton.isDisabled())

        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.shareLink))
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.copyLink))
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.removePassword))
    }

    /// Setting `isSendHideEmailDisabled` disables the hide email control within the view.
    @MainActor
    func test_sendHideEmailDisabled() async throws {
        processor.state.isSendHideEmailDisabled = true

        let infoContainer = try subject.inspect().find(InfoContainer<Text>.self)
        try XCTAssertEqual(infoContainer.text().string(), Localizations.sendOptionsPolicyInEffect)
    }

    /// Updating the text textfield sends the `.textChanged` action.
    @MainActor
    func test_textTextField_updated() throws {
        let textField = try subject.inspect().find(
            type: BitwardenUITextViewType.self,
            accessibilityLabel: Localizations.textToShare
        )
        try textField.inputBinding().wrappedValue = "Text"
        XCTAssertEqual(processor.dispatchedActions.last, .textChanged("Text"))
    }

    // MARK: Snapshots

    @MainActor
    func test_snapshot_file_empty() {
        processor.state.type = .file
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 1.1)]
        )
    }

    @MainActor
    func test_snapshot_file_withValues() {
        processor.state.type = .file
        processor.state.name = "Name"
        processor.state.fileName = "example_file.txt"
        processor.state.fileData = Data("example".utf8)
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    @MainActor
    func test_snapshot_file_withValues_prefilled() {
        processor.state.type = .file
        processor.state.name = "Name"
        processor.state.fileName = "example_file.txt"
        processor.state.fileData = Data("example".utf8)
        processor.state.mode = .shareExtension(.empty())
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    @MainActor
    func test_snapshot_file_withOptions_empty() {
        processor.state.type = .file
        processor.state.isOptionsExpanded = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func test_snapshot_file_withOptions_withValues() {
        processor.state.type = .file
        processor.state.isOptionsExpanded = true
        processor.state.name = "Name"
        processor.state.fileName = "example_file.txt"
        processor.state.fileData = Data("example".utf8)
        processor.state.isHideTextByDefaultOn = true
        processor.state.deletionDate = .custom(deletionDate)
        processor.state.customDeletionDate = deletionDate
        processor.state.maximumAccessCount = 42
        processor.state.maximumAccessCountText = "42"
        processor.state.password = "pa$$w0rd"
        processor.state.notes = "Notes"
        processor.state.isHideMyEmailOn = true
        processor.state.isDeactivateThisSendOn = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func test_snapshot_file_edit_withOptions_withValues() {
        processor.state.mode = .edit
        processor.state.type = .file
        processor.state.isOptionsExpanded = true
        processor.state.name = "Name"
        processor.state.fileName = "example_file.txt"
        processor.state.fileSize = "420.42 KB"
        processor.state.deletionDate = .custom(deletionDate)
        processor.state.customDeletionDate = deletionDate
        processor.state.maximumAccessCount = 420
        processor.state.maximumAccessCountText = "420"
        processor.state.currentAccessCount = 42
        processor.state.password = "pa$$w0rd"
        processor.state.notes = "Notes"
        processor.state.isHideMyEmailOn = true
        processor.state.isDeactivateThisSendOn = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func test_snapshot_sendDisabled() {
        processor.state.isSendDisabled = true
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    @MainActor
    func test_snapshot_sendHideEmailDisabled() {
        processor.state.isSendHideEmailDisabled = true
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    @MainActor
    func test_snapshot_text_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    @MainActor
    func test_snapshot_text_withValues() {
        processor.state.name = "Name"
        processor.state.text = "Text"
        processor.state.isHideTextByDefaultOn = true
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    @MainActor
    func test_snapshot_text_withOptions_empty() {
        processor.state.isOptionsExpanded = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func test_snapshot_text_withOptions_withValues() {
        processor.state.isOptionsExpanded = true
        processor.state.name = "Name"
        processor.state.text = "Text."
        processor.state.isHideTextByDefaultOn = true
        processor.state.deletionDate = .custom(deletionDate)
        processor.state.customDeletionDate = deletionDate
        processor.state.maximumAccessCount = 42
        processor.state.maximumAccessCountText = "42"
        processor.state.password = "pa$$w0rd"
        processor.state.notes = "Notes."
        processor.state.isHideMyEmailOn = true
        processor.state.isDeactivateThisSendOn = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func test_snapshot_text_edit_withOptions_withValues() {
        processor.state.mode = .edit
        processor.state.type = .text
        processor.state.isOptionsExpanded = true
        processor.state.name = "Name"
        processor.state.text = "Text"
        processor.state.deletionDate = .custom(deletionDate)
        processor.state.customDeletionDate = deletionDate
        processor.state.maximumAccessCount = 420
        processor.state.maximumAccessCountText = "420"
        processor.state.currentAccessCount = 42
        processor.state.password = "pa$$w0rd"
        processor.state.notes = "Notes"
        processor.state.isHideMyEmailOn = true
        processor.state.isDeactivateThisSendOn = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func test_snapshot_text_extension_withValues() {
        processor.state.mode = .shareExtension(.singleAccount)
        processor.state.type = .text
        processor.state.name = "Name"
        processor.state.text = "Text"
        processor.state.isHideTextByDefaultOn = true
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }
}
