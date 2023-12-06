import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - ViewItemViewTests

class ViewItemViewTests: BitwardenTestCase {
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
            cipherView: .loginFixture(
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
            cipherView: .loginFixture(
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
                login: .fixture(password: "password"),
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
            cipherView: .loginFixture(
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

    // MARK: Snapshots

    func test_snapshot_loading() {
        processor.state.loadingState = .loading
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func loginState() -> LoginItemState { // swiftlint:disable:this function_body_length
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
                match: .startsWith,
                uri: "https://www.example.com"
            ),
            .init(
                match: .exact,
                uri: "https://www.example.com/account/login"
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
        return loginState
    }

    func test_snapshot_login_withAllValues() {
        processor.state.loadingState = .data(.login(loginState()))
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_login_withAllValues_largeText() {
        processor.state.loadingState = .data(.login(loginState()))
        assertSnapshot(of: subject, as: .tallPortraitAX5(heightMultiple: 6))
    }
}
