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
        let loginState = CipherItemState(
            existing: .loginFixture(
                login: .fixture(
                    password: "password"
                ),
                name: "Name",
                revisionDate: Date()
            )
        )!
        processor.state.loadingState = .data(loginState)
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.checkPassword)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .checkPasswordPressed)
    }

    /// Tapping the copy usename button dispatches the `.copyPressed` action with the username.
    func test_copyUsernameButton_tap() throws {
        let loginState = CipherItemState(
            existing: .loginFixture(
                login: .fixture(
                    username: "username"
                ),
                name: "Name",
                revisionDate: Date()
            )
        )!
        processor.state.loadingState = .data(loginState)
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copy)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "username"))
    }

    /// Tapping the copy password button dispatches the `.copyPressed` action along with the
    /// password.
    func test_copyPasswordButton_tap() throws {
        let loginState = CipherItemState(
            existing: .loginFixture(
                login: .fixture(password: "password"),
                revisionDate: Date()
            )
        )!
        processor.state.loadingState = .data(loginState)
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copy)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "password"))
    }

    /// Tapping the copy uri button dispatches the `.copyPressed` action along with the uri.
    func test_copyUriButton_tap() throws {
        let loginState = CipherItemState(
            existing: .loginFixture(
                login: .fixture(
                    uris: [
                        .init(uri: "www.example.com", match: nil),
                    ]
                ),
                name: "Name",
                revisionDate: Date()
            )
        )!
        processor.state.loadingState = .data(loginState)
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

    func identityState() -> CipherItemState {
        var cipherState = CipherItemState(existing: .fixture(id: "1234", name: "identity example", type: .identity))!
        cipherState.folder = "Folder"
        cipherState.notes = "This is a long note so that it goes to the next line!"
        cipherState.updatedDate = Date(year: 2023, month: 11, day: 11, hour: 9, minute: 41)
        cipherState.identityState = .fixture(
            title: .custom(.dr),
            firstName: "First",
            lastName: "Last",
            middleName: "Middle",
            userName: "userName",
            company: "Company name",
            socialSecurityNumber: "12-345-6789",
            passportNumber: "passport #",
            licenseNumber: "license #",
            email: "hello@email.com",
            phone: "(123) 456-7890",
            address1: "123 street",
            address2: "address2",
            address3: "address3",
            cityOrTown: "City",
            state: "State",
            postalCode: "1234",
            country: "country"
        )
        return cipherState
    }

    func loginState() -> CipherItemState { // swiftlint:disable:this function_body_length
        var cipherState = CipherItemState(existing: .fixture(id: "fake-id"))!
        cipherState.folder = "Folder"
        cipherState.loginState.isPasswordVisible = true
        cipherState.name = "Example"
        cipherState.notes = "This is a long note so that it goes to the next line!"
        cipherState.loginState.password = "Password1234!"
        cipherState.loginState.passwordUpdatedDate = Date(year: 2023, month: 11, day: 11, hour: 9, minute: 41)
        cipherState.updatedDate = Date(year: 2023, month: 11, day: 11, hour: 9, minute: 41)
        cipherState.loginState.uris = [
            UriState(
                matchType: .custom(.startsWith),
                uri: "https://www.example.com"
            ),
            UriState(
                matchType: .custom(.exact),
                uri: "https://www.example.com/account/login"
            ),
        ]
        cipherState.loginState.username = "email@example.com"
        cipherState.loginState.isPasswordVisible = true
        cipherState.customFields = [
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
        return cipherState
    }

    func test_snapshot_identity_withAllValues() {
        processor.state.loadingState = .data(identityState())
        assertSnapshot(of: subject, as: .tallPortrait2)
    }

    func test_snapshot_login_withAllValues() {
        processor.state.loadingState = .data(loginState())
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_login_withAllValues_largeText() {
        processor.state.loadingState = .data(loginState())
        assertSnapshot(of: subject, as: .tallPortraitAX5(heightMultiple: 6))
    }
}
