import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - ViewItemViewTests

class ViewItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ViewItemState, ViewItemAction, Void>!
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
        processor.state.typeState = .login(ViewLoginItemState(
            name: "Name",
            password: "password",
            updatedDate: Date()
        ))
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.checkPassword)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .checkPasswordPressed)
    }

    /// Tapping the copy usename button dispatches the `.copyPressed` action with the username.
    func test_copyUsernameButton_tap() throws {
        processor.state.typeState = .login(ViewLoginItemState(
            name: "Name",
            updatedDate: Date(),
            username: "username"
        ))
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copy)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "username"))
    }

    /// Tapping the copy password button dispatches the `.copyPressed` action along with the
    /// password.
    func test_copyPasswordButton_tap() throws {
        processor.state.typeState = .login(ViewLoginItemState(
            name: "Name",
            password: "password",
            updatedDate: Date()
        ))
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copy)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "password"))
    }

    /// Tapping the copy uri button dispatches the `.copyPressed` action along with the uri.
    func test_copyUriButton_tap() throws {
        processor.state.typeState = .login(ViewLoginItemState(
            name: "Name",
            updatedDate: Date(),
            uris: [
                .init(uri: "www.example.com", match: nil),
            ]
        ))
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
        processor.state.typeState = .loading
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_login_withAllValues() {
        processor.state.typeState = .login(.init(
            customFields: [
                .init(
                    name: "Field Name",
                    value: "Value",
                    type: .text,
                    linkedId: nil
                ),
            ],
            folder: "Folder",
            isPasswordVisible: true,
            name: "Example",
            notes: "This is a long note so that it goes to the next line!",
            password: "Password1234!",
            updatedDate: Date(year: 2023, month: 11, day: 11, hour: 9, minute: 41),
            uris: [
                .init(
                    uri: "https://www.example.com",
                    match: .startsWith
                ),
                .init(
                    uri: "https://www.example.com/account/login",
                    match: .exact
                ),
            ],
            username: "email@example.com"
        ))
        assertSnapshot(of: subject, as: .tallPortrait)
    }
}
