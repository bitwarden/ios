// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SwiftUI
import ViewInspector
import ViewInspectorTestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - AddEditSendItemViewTests

class AddEditSendItemViewTests: BitwardenTestCase {
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
        let button = try subject.inspect().findCancelToolbarButton()
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
            containing: Localizations.maximumAccessCount,
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

    /// Updating the notes textfield sends the `.notesChanged` action.
    @MainActor
    func test_notesTextField_updated() throws {
        processor.state.isOptionsExpanded = true
        let textField = try subject.inspect().find(
            type: BitwardenUITextViewType.self,
            accessibilityLabel: Localizations.privateNote,
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
        guard #unavailable(iOS 26) else {
            // TODO: PM-26079 Remove when toolbar AsyncButton is used.
            throw XCTSkip("Remove this when the toolbar save button gets updated to use AsyncButton.")
        }

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

        let saveButton = try subject.inspect().findSaveToolbarButton()
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
            accessibilityLabel: Localizations.textToShare,
        )
        try textField.inputBinding().wrappedValue = "Text"
        XCTAssertEqual(processor.dispatchedActions.last, .textChanged("Text"))
    }

    // MARK: Who Can View Tests

    /// Updating the access type menu sends the `.accessTypeChanged` action.
    @MainActor
    func test_accessTypeMenu_updated() throws {
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.whoCanView)
        try menuField.select(newValue: SendAccessType.anyoneWithPassword)
        XCTAssertEqual(processor.dispatchedActions.last, .accessTypeChanged(.anyoneWithPassword))
    }

    /// Updating the password textfield when "Anyone with password" is selected sends the `.passwordChanged` action.
    @MainActor
    func test_passwordTextField_updated() throws {
        processor.state.accessType = .anyoneWithPassword
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.password)
        try textField.inputBinding().wrappedValue = "password123"
        XCTAssertEqual(processor.dispatchedActions.last, .passwordChanged("password123"))
    }

    /// Tapping the generate password button sends the `.generatePasswordPressed` action.
    @MainActor
    func test_generatePasswordButton_tap() throws {
        processor.state.accessType = .anyoneWithPassword
        let button = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.generatePassword,
        )
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .generatePasswordPressed)
    }

    /// Tapping the copy password button performs the `.copyPasswordPressed` effect.
    @MainActor
    func test_copyPasswordButton_tap() async throws {
        processor.state.accessType = .anyoneWithPassword
        processor.state.password = "testPassword123"
        let button = try subject.inspect().find(
            asyncButtonWithAccessibilityLabel: Localizations.copyPassword,
        )
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .copyPasswordPressed)
    }

    /// The copy password button is not visible when the password is empty.
    @MainActor
    func test_copyPasswordButton_notVisibleWhenEmpty() throws {
        processor.state.accessType = .anyoneWithPassword
        processor.state.password = ""
        XCTAssertThrowsError(
            try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.copyPassword),
        )
    }

    /// Tapping the add email button sends the `.addRecipientEmail` action.
    @MainActor
    func test_addEmailButton_tap() throws {
        processor.state.accessType = .specificPeople
        processor.state.recipientEmails = ["test@example.com"]
        let button = try subject.inspect().find(button: Localizations.addEmail)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addRecipientEmail)
    }

    /// Updating a recipient email textfield sends the `.recipientEmailChanged` action.
    @MainActor
    func test_recipientEmailTextField_updated() throws {
        processor.state.accessType = .specificPeople
        processor.state.recipientEmails = [""]
        let textField = try subject.inspect()
            .find(viewWithAccessibilityIdentifier: "SendRecipientEmailEntry0")
            .find(ViewType.TextField.self)
        try textField.setInput("test@example.com")
        XCTAssertEqual(processor.dispatchedActions.last, .recipientEmailChanged(index: 0, value: "test@example.com"))
    }

    /// Tapping the remove email button sends the `.removeRecipientEmail` action.
    @MainActor
    func test_removeEmailButton_tap() throws {
        processor.state.accessType = .specificPeople
        processor.state.recipientEmails = ["test@example.com", "another@example.com"]
        let button = try subject.inspect()
            .find(viewWithAccessibilityIdentifier: "RemoveRecipientEmailButton0")
            .button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .removeRecipientEmail(index: 0))
    }
}
