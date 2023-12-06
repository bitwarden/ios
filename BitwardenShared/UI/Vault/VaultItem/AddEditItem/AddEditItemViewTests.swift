import BitwardenSdk
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - AddEditItemViewTests

class AddEditItemViewTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var processor: MockProcessor<AddEditItemState, AddEditItemAction, AddEditItemEffect>!
    var subject: AddEditItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: .addItem())
        let store = Store(processor: processor)
        subject = AddEditItemView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismissPressed` action.
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the check password button performs the `.checkPassword` effect.
    func test_checkPasswordButton_tap() async throws {
        let button = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.checkPassword)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .checkPasswordPressed)
    }

    /// Tapping the dismiss button dispatches the `.dismissPressed` action.
    func test_dismissButton_tap() throws {
        processor.state = AddEditItemState.editItem(cipherView: CipherView.loginFixture())!
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.close)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the favorite toggle dispatches the `.favoriteChanged(_:)` action.
    func test_favoriteToggle_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        processor.state.properties.isFavoriteOn = false
        let toggle = try subject.inspect().find(ViewType.Toggle.self, containing: Localizations.favorite)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .favoriteChanged(true))
    }

    /// Updating the folder text field dispatches the `.folderChanged()` action.
    func test_folderTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.folder)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .folderChanged("text"))
    }

    /// Tapping the generate password button dispatches the `.generatePasswordPressed` action.
    func test_generatePasswordButton_tap() throws {
        let button = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.generatePassword
        )
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .generatePasswordPressed)
    }

    /// Tapping the generate username button dispatches the `.generateUsernamePressed` action.
    func test_generateUsernameButton_tap() throws {
        let button = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.generateUsername
        )
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .generateUsernamePressed)
    }

    /// Tapping the master password re-prompt toggle dispatches the `.masterPasswordRePromptChanged(_:)` action.
    func test_masterPasswordRePromptToggle_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        processor.state.properties.isMasterPasswordRePromptOn = false
        let toggle = try subject.inspect().find(ViewType.Toggle.self, containing: Localizations.passwordPrompt)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordRePromptChanged(true))
    }

    /// Tapping the more button dispatches the `.morePressed` action.
    func test_moreButton_tap() throws {
        processor.state = AddEditItemState.editItem(cipherView: CipherView.loginFixture())!
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.options)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .morePressed)
    }

    /// Updating the name text field dispatches the `.nameChanged()` action.
    func test_nameTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.name)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .nameChanged("text"))
    }

    /// Tapping the new custom field button dispatches the `.newCustomFieldPressed` action.
    func test_newCustomFieldButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.newCustomField)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .newCustomFieldPressed)
    }

    /// Tapping the new uri button dispatches the `.newUriPressed` action.
    func test_newUriButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.newUri)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .newUriPressed)
    }

    /// Updating the notes text field dispatches the `.notesChanged()` action.
    func test_notesTextField_updateValue() throws {
        let textField = try subject.inspect().find(
            bitwardenTextFieldWithAccessibilityLabel: Localizations.notes
        )
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .notesChanged("text"))
    }

    /// Updating the owner text field dispatches the `.ownerChanged()` action.
    func test_ownerTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.whoOwnsThisItem)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .ownerChanged("text"))
    }

    /// Updating the password text field dispatches the `.passwordChanged()` action.
    func test_passwordTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.password)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .passwordChanged("text"))
    }

    /// Tapping the password visibility button dispatches the `.togglePasswordVisibilityChanged(_:)` action.
    func test_passwordVisibilityButton_tap_withPasswordNotVisible() throws {
        processor.state.isPasswordVisible = false
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.password)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsNotVisibleTapToShow)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .togglePasswordVisibilityChanged(true))
    }

    /// Tapping the password visibility button dispatches the `.togglePasswordVisibilityChanged(_:)` action.
    func test_passwordVisibilityButton_tap_withPasswordVisible() throws {
        processor.state.isPasswordVisible = true
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.password)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsVisibleTapToHide)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .togglePasswordVisibilityChanged(false))
    }

    /// Tapping the save button performs the `.savePressed` effect.
    func test_saveButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()

        XCTAssertEqual(processor.effects.last, .savePressed)
    }

    /// Tapping the setup totp button disptaches the `.setupTotpPressed` action.
    func test_setupTotpButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.setupTotp)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .setupTotpPressed)
    }

    func test_typeMenuField_updateValue() throws {
        processor.state.properties.type = .login
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.type)
        try menuField.select(newValue: BitwardenShared.CipherType.card)
        XCTAssertEqual(processor.dispatchedActions.last, .typeChanged(.card))
    }

    /// Tapping the uri settings button dispatches the `.uriSettingsPressed` action.
    func test_uriSettingsButton_tap() throws {
        let button = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.uriMatchDetection
        )
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .uriSettingsPressed)
    }

    /// Updating the uri text field dispatches the `.uriChanged()` action.
    func test_uriTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.uri)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .uriChanged("text", index: 0))
    }

    /// Updating the name text field dispatches the `.usernameChanged()` action.
    func test_usernameTextField_updateValue() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.username)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .usernameChanged("text"))
    }

    // MARK: Snapshots

    func test_snapshot_empty() {
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_full_fieldsVisible() {
        processor.state.properties.type = .login
        processor.state.properties.name = "Name"
        processor.state.properties.username = "username"
        processor.state.properties.password = "password1!"
        processor.state.properties.isFavoriteOn = true
        processor.state.properties.isMasterPasswordRePromptOn = true
        processor.state.properties.uris = [
            .init(match: nil, uri: URL.example.absoluteString),
        ]
        processor.state.properties.owner = "owner"
        processor.state.properties.notes = "Notes"
        processor.state.properties.folder = "Folder"

        processor.state.isPasswordVisible = true

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_secureNote_full_fieldsVisible() {
        processor.state.properties.type = .secureNote
        processor.state.properties.name = "Secure Note Name"
        processor.state.properties.isFavoriteOn = true
        processor.state.properties.isMasterPasswordRePromptOn = true
        processor.state.properties.owner = "owner"
        processor.state.properties.notes = "Notes"
        processor.state.properties.folder = "Folder"

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_full_fieldsNotVisible() {
        processor.state.properties.type = .login
        processor.state.properties.name = "Name"
        processor.state.properties.username = "username"
        processor.state.properties.password = "password1!"
        processor.state.properties.isFavoriteOn = true
        processor.state.properties.isMasterPasswordRePromptOn = true
        processor.state.properties.uris = [
            .init(match: nil, uri: URL.example.absoluteString),
        ]
        processor.state.properties.owner = "owner"
        processor.state.properties.notes = "Notes"
        processor.state.properties.folder = "Folder"

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot__edit_full_fieldsVisible() {
        processor.state = AddEditItemState.editItem(cipherView: CipherView.loginFixture())!
        processor.state.properties.type = .login
        processor.state.properties.name = "Name"
        processor.state.properties.username = "username"
        processor.state.properties.password = "password1!"
        processor.state.properties.isFavoriteOn = true
        processor.state.properties.isMasterPasswordRePromptOn = true
        processor.state.properties.uris = [
            .init(match: nil, uri: URL.example.absoluteString),
        ]
        processor.state.properties.owner = "owner"
        processor.state.properties.notes = "Notes"
        processor.state.properties.folder = "Folder"

        processor.state.isPasswordVisible = true

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot__edit_full_fieldsVisible_largeText() {
        processor.state = AddEditItemState.editItem(cipherView: CipherView.loginFixture())!
        processor.state.properties.type = .login
        processor.state.properties.name = "Name"
        processor.state.properties.username = "username"
        processor.state.properties.password = "password1!"
        processor.state.properties.isFavoriteOn = true
        processor.state.properties.isMasterPasswordRePromptOn = true
        processor.state.properties.uris = [
            .init(match: nil, uri: URL.example.absoluteString),
        ]
        processor.state.properties.owner = "owner"
        processor.state.properties.notes = "Notes"
        processor.state.properties.folder = "Folder"

        processor.state.isPasswordVisible = true

        assertSnapshot(of: subject, as: .tallPortraitAX5())
    }

    func test_snapshot__edit_full_fieldsNotVisible() {
        processor.state = AddEditItemState.editItem(cipherView: CipherView.loginFixture())!
        processor.state.properties.type = .login
        processor.state.properties.name = "Name"
        processor.state.properties.username = "username"
        processor.state.properties.password = "password1!"
        processor.state.properties.isFavoriteOn = true
        processor.state.properties.isMasterPasswordRePromptOn = true
        processor.state.properties.uris = [
            .init(match: nil, uri: URL.example.absoluteString),
        ]
        processor.state.properties.owner = "owner"
        processor.state.properties.notes = "Notes"
        processor.state.properties.folder = "Folder"

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot__edit_full_fieldsNotVisible_largeText() {
        processor.state = AddEditItemState.editItem(cipherView: CipherView.loginFixture())!
        processor.state.properties.type = .login
        processor.state.properties.name = "Name"
        processor.state.properties.username = "username"
        processor.state.properties.password = "password1!"
        processor.state.properties.isFavoriteOn = true
        processor.state.properties.isMasterPasswordRePromptOn = true
        processor.state.properties.uris = [
            .init(match: nil, uri: URL.example.absoluteString),
        ]
        processor.state.properties.owner = "owner"
        processor.state.properties.notes = "Notes"
        processor.state.properties.folder = "Folder"

        assertSnapshot(of: subject, as: .tallPortraitAX5())
    }
}
