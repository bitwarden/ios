import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - ViewItemViewTests

class ViewItemViewTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var processor: MockProcessor<ViewItemState, ViewItemAction, ViewItemEffect>!
    var subject: ViewItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let state = ViewItemState()
        processor = MockProcessor(state: state)
        let store = Store(processor: processor)
        subject = ViewItemView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the check password button dispatches the `.checkPasswordPressed` action.
    func test_checkPasswordButton_tap() throws {
        let loginState = LoginItemState(
            cipherView: .fixture(
                login: .fixture(
                    password: "password"
                ),
                name: "Name",
                revisionDate: Date()
            )
        )!
        processor.state.loadingState = .data(.login(loginState))
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.checkPassword)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .checkPasswordPressed)
    }

    /// Tapping the copy usename button dispatches the `.copyPressed` action with the username.
    func test_copyUsernameButton_tap() throws {
        let loginState = LoginItemState(
            cipherView: .fixture(
                login: .fixture(
                    username: "username"
                ),
                name: "Name",
                revisionDate: Date()
            )
        )!
        processor.state.loadingState = .data(.login(loginState))
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copy)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "username"))
    }

    /// Tapping the copy password button dispatches the `.copyPressed` action along with the
    /// password.
    func test_copyPasswordButton_tap() throws {
        let loginState = LoginItemState(
            cipherView: .loginFixture(
                password: "password",
                revisionDate: Date()
            )
        )!
        processor.state.loadingState = .data(.login(loginState))
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copy)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "password"))
    }

    /// Tapping the copy uri button dispatches the `.copyPressed` action along with the uri.
    func test_copyUriButton_tap() throws {
        let loginState = LoginItemState(
            cipherView: .fixture(
                login: .fixture(
                    uris: [
                        .init(uri: "www.example.com", match: nil),
                    ]
                ),
                name: "Name",
                revisionDate: Date()
            )
        )!
        processor.state.loadingState = .data(.login(loginState))
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copy)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "www.example.com"))
    }

    /// Tapping the save button dispatches the `.savePressed` action.
    func test_saveButton_tap() async throws {
        var loginState = LoginItemState(
            cipherView: .fixture(
                login: .fixture(
                    uris: [
                        .init(uri: "www.example.com", match: nil),
                    ]
                ),
                name: "Name",
                revisionDate: Date()
            )
        )!
        loginState.editState = .edit(
            .init(
                isPasswordVisible: true,
                properties: loginState.properties
            )
        )
        processor.state.loadingState = .data(.login(loginState))
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .savePressed)
    }

    /// Tapping the dismiss button dispatches the `.dismissPressed` action.
    func test_dismissButton_tap() throws {
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.close)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the more button dispatches the `.morePressed` action.
    func test_moreButton_tap() throws {
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.options)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .morePressed)
    }

    /// Tapping the favorite toggle dispatches the `.favoriteChanged(_:)` action.
    func test_favoriteToggle_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        var loginState = LoginItemState(
            cipherView: .loginFixture(
                favorite: true,
                name: "Name",
                revisionDate: Date()
            )
        )!
        loginState.editState = .edit(
            .init(
                isPasswordVisible: true,
                properties: loginState.properties
            )
        )
        processor.state.loadingState = .data(.login(loginState))
        let toggle = try subject.inspect().find(ViewType.Toggle.self, containing: Localizations.favorite)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .editAction(.favoriteChanged(true)))
    }

    /// Tapping the master password re-prompt toggle dispatches the `.masterPasswordRePromptChanged(_:)` action.
    func test_masterPasswordRePromptToggle_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        var loginState = LoginItemState(
            cipherView: .loginFixture(
                name: "Name",
                reprompt: .password,
                revisionDate: Date()
            )
        )!
        loginState.editState = .edit(
            .init(
                isPasswordVisible: true,
                properties: loginState.properties
            )
        )
        let toggle = try subject.inspect().find(ViewType.Toggle.self, containing: Localizations.passwordPrompt)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .editAction(.masterPasswordRePromptChanged(false)))
    }

    /// Updating the name text field dispatches the `.nameChanged()` action.
    func test_nameTextField_updateValue() throws {
        var loginState = LoginItemState(
            cipherView: .loginFixture(
                name: "Name",
                revisionDate: Date()
            )
        )!
        loginState.editState = .edit(
            .init(
                isPasswordVisible: true,
                properties: loginState.properties
            )
        )
        processor.state.loadingState = .data(.login(loginState))
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.name)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .editAction(.nameChanged("text")))
    }

    /// Tapping the new uri button dispatches the `.newUriPressed` action.
    func test_newUriButton_tap() throws {
        var loginState = LoginItemState(
            cipherView: .loginFixture(
                name: "Name",
                revisionDate: Date()
            )
        )!
        loginState.editState = .edit(
            .init(
                isPasswordVisible: true,
                properties: loginState.properties
            )
        )
        processor.state.loadingState = .data(.login(loginState))
        let button = try subject.inspect().find(button: Localizations.newUri)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .editAction(.newUriPressed))
    }

    /// Updating the notes text field dispatches the `.notesChanged()` action.
    func test_notesTextField_updateValue() throws {
        var loginState = LoginItemState(
            cipherView: .loginFixture(
                name: "Name",
                revisionDate: Date()
            )
        )!
        loginState.editState = .edit(
            .init(
                isPasswordVisible: true,
                properties: loginState.properties
            )
        )
        processor.state.loadingState = .data(.login(loginState))
        let textField = try subject.inspect().find(
            bitwardenTextFieldWithAccessibilityLabel: Localizations.notes
        )
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .editAction(.notesChanged("text")))
    }

    /// Updating the password text field dispatches the `.passwordChanged()` action.
    func test_passwordTextField_updateValue() throws {
        var loginState = LoginItemState(
            cipherView: .loginFixture(
                name: "Name",
                revisionDate: Date()
            )
        )!
        loginState.editState = .edit(
            .init(
                isPasswordVisible: true,
                properties: loginState.properties
            )
        )
        processor.state.loadingState = .data(.login(loginState))
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.password)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .editAction(.passwordChanged("text")))
    }

    /// Tapping the password visibility button dispatches the `.togglePasswordVisibilityChanged(_:)` action.
    func test_passwordVisibilityButton_tap_withPasswordNotVisible() throws {
        var loginState = LoginItemState(
            cipherView: .loginFixture(
                name: "Name",
                revisionDate: Date()
            )
        )!
        loginState.editState = .edit(
            .init(
                isPasswordVisible: false,
                properties: loginState.properties
            )
        )
        processor.state.loadingState = .data(.login(loginState))
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.password)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsNotVisibleTapToShow)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .editAction(.togglePasswordVisibilityChanged(true)))
    }

    /// Tapping the password visibility button dispatches the `.togglePasswordVisibilityChanged(_:)` action.
    func test_passwordVisibilityButton_tap_withPasswordVisible() throws {
        var loginState = LoginItemState(
            cipherView: .loginFixture(
                name: "Name",
                revisionDate: Date()
            )
        )!
        loginState.editState = .edit(
            .init(
                isPasswordVisible: true,
                properties: loginState.properties
            )
        )
        processor.state.loadingState = .data(.login(loginState))
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.password)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsVisibleTapToHide)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .editAction(.togglePasswordVisibilityChanged(false)))
    }

    /// Tapping the setup totp button disptaches the `.setupTotpPressed` action.
    func test_setupTotpButton_tap() async throws {
        var loginState = LoginItemState(
            cipherView: .loginFixture(
                name: "Name",
                revisionDate: Date()
            )
        )!
        loginState.editState = .edit(
            .init(
                isPasswordVisible: true,
                properties: loginState.properties
            )
        )
        processor.state.loadingState = .data(.login(loginState))
        let button = try subject.inspect().find(asyncButton: Localizations.setupTotp)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .setupTotpPressed)
    }

    /// Updating the name text field dispatches the `.usernameChanged()` action.
    func test_usernameTextField_updateValue() throws {
        var loginState = LoginItemState(
            cipherView: .loginFixture(
                name: "Name",
                revisionDate: Date()
            )
        )!
        loginState.editState = .edit(
            .init(
                isPasswordVisible: true,
                properties: loginState.properties
            )
        )
        processor.state.loadingState = .data(.login(loginState))
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.username)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .editAction(.usernameChanged("text")))
    }

    // MARK: Snapshots

    func test_snapshot_loading() {
        processor.state.loadingState = .loading
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    // swiftlint:disable:next function_body_length
    func test_snapshot_login_withAllValues() {
        var loginState = LoginItemState(cipherView: .loginFixture())!
        loginState.properties.folder = "Folder"
        loginState.isPasswordVisible = true
        loginState.properties.name = "Example"
        loginState.properties.notes = "This is a long note so that it goes to the next line!"
        loginState.properties.password = "Password1234!"
        loginState.properties.passwordUpdatedDate = Date(year: 2023, month: 11, day: 11, hour: 9, minute: 41)
        loginState.properties.updatedDate = Date(year: 2023, month: 11, day: 11, hour: 9, minute: 41)
        loginState.properties.uris = [
            .init(
                uri: "https://www.example.com",
                match: .startsWith
            ),
            .init(
                uri: "https://www.example.com/account/login",
                match: .exact
            ),
        ]
        loginState.properties.username = "email@example.com"
        loginState.isPasswordVisible = true
        loginState.properties.customFields = [
            CustomFieldState(
                linkedIdType: nil,
                name: "Text",
                type: .text,
                value: "Value"
            ),
            CustomFieldState(
                linkedIdType: nil,
                name: "Text empty",
                type: .text,
                value: nil
            ),
            CustomFieldState(
                isPasswordVisible: false,
                linkedIdType: nil,
                name: "Hidden Hidden",
                type: .hidden,
                value: "pa$$w0rd"
            ),
            CustomFieldState(
                isPasswordVisible: true,
                linkedIdType: nil,
                name: "Hidden Shown",
                type: .hidden,
                value: "pa$$w0rd"
            ),
            CustomFieldState(
                linkedIdType: nil,
                name: "Boolean True",
                type: .boolean,
                value: "true"
            ),
            CustomFieldState(
                linkedIdType: nil,
                name: "Boolean False",
                type: .boolean,
                value: "false"
            ),
            CustomFieldState(
                linkedIdType: .loginUsername,
                name: "Linked",
                type: .linked,
                value: nil
            ),
        ]
        processor.state.loadingState = .data(.login(loginState))
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    // swiftlint:disable:next function_body_length
    func test_snapshot_login_edit_withAllValues() {
        var loginState = LoginItemState(cipherView: .loginFixture())!
        loginState.properties.folder = "Folder"
        loginState.isPasswordVisible = true
        loginState.properties.name = "Example"
        loginState.properties.notes = "This is a long note so that it goes to the next line!"
        loginState.properties.password = "Password1234!"
        loginState.properties.passwordUpdatedDate = Date(year: 2023, month: 11, day: 11, hour: 9, minute: 41)
        loginState.properties.updatedDate = Date(year: 2023, month: 11, day: 11, hour: 9, minute: 41)
        loginState.properties.uris = [
            .init(
                uri: "https://www.example.com",
                match: .startsWith
            ),
            .init(
                uri: "https://www.example.com/account/login",
                match: .exact
            ),
        ]
        loginState.properties.username = "email@example.com"
        loginState.isPasswordVisible = true
        loginState.properties.customFields = [
            CustomFieldState(
                linkedIdType: nil,
                name: "Text",
                type: .text,
                value: "Value"
            ),
            CustomFieldState(
                linkedIdType: nil,
                name: "Text empty",
                type: .text,
                value: nil
            ),
            CustomFieldState(
                isPasswordVisible: false,
                linkedIdType: nil,
                name: "Hidden Hidden",
                type: .hidden,
                value: "pa$$w0rd"
            ),
            CustomFieldState(
                isPasswordVisible: true,
                linkedIdType: nil,
                name: "Hidden Shown",
                type: .hidden,
                value: "pa$$w0rd"
            ),
            CustomFieldState(
                linkedIdType: nil,
                name: "Boolean True",
                type: .boolean,
                value: "true"
            ),
            CustomFieldState(
                linkedIdType: nil,
                name: "Boolean False",
                type: .boolean,
                value: "false"
            ),
            CustomFieldState(
                linkedIdType: .loginUsername,
                name: "Linked",
                type: .linked,
                value: nil
            ),
        ]
        loginState.editState = .edit(
            .init(
                isPasswordVisible: loginState.isPasswordVisible,
                properties: loginState.properties
            )
        )
        processor.state.loadingState = .data(.login(loginState))
        assertSnapshot(of: subject, as: .tallPortrait)
    }
} // swiftlint:disable:this file_length
