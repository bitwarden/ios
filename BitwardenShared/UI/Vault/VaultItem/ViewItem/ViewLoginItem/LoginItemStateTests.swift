import BitwardenSdk
import XCTest

@testable import BitwardenShared

class LoginItemStateTests: BitwardenTestCase {
    // MARK: Propteries

    var subject: LoginItemState!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = .init(cipherView: .loginFixture())
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    /// A cipher without a login fails to create a login state.
    func test_init_failure() {
        let nilSubject = LoginItemState(cipherView: .fixture())
        XCTAssertNil(nilSubject)
    }

    /// A cipher with a login creates a login state.
    func test_init_success() {
        let nonNil = LoginItemState(cipherView: .loginFixture())
        XCTAssertNotNil(nonNil)
        XCTAssertEqual(nonNil?.properties.customFields, [])
        XCTAssertEqual(nonNil?.properties.uris, [.init(match: nil, uri: nil)])
    }

    /// A cipher without a login fails to create a login state.
    func test_cipherItemProperties_init_failure() {
        let nilSubject = CipherItemProperties.from(.fixture())
        XCTAssertNil(nilSubject)
    }

    /// A cipher with a login creates a login state.
    func test_cipherItemProperties_init_success() {
        let nonNil = CipherItemProperties.from(.loginFixture())
        XCTAssertNotNil(nonNil)
        XCTAssertEqual(nonNil?.customFields, [])
        XCTAssertEqual(nonNil?.uris, [.init(match: nil, uri: nil)])
    }

    /// A cipher with custom fields relays the properties.
    func test_init_success_customFields_empty() {
        let fields: [FieldView] = []
        subject = LoginItemState(
            cipherView: .loginFixture(
                fields: fields
            )
        )
        XCTAssertEqual(subject.properties.customFields, [])
    }

    /// A cipher with custom fields relays the properties.
    func test_init_success_customFields_populated() { // swiftlint:disable:this function_body_length
        let fields: [FieldView] = [
            .init(name: "Text", value: "Value", type: .text, linkedId: nil),
            .init(name: "Text empty", value: nil, type: .text, linkedId: nil),
            .init(name: "Hidden", value: "pa$$w0rd", type: .hidden, linkedId: nil),
            .init(name: "Boolean True", value: "true", type: .boolean, linkedId: nil),
            .init(name: "Boolean False", value: "false", type: .boolean, linkedId: nil),
            .init(name: "Linked", value: nil, type: .linked, linkedId: 100),
        ]
        let expectations = [
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
                name: "Hidden",
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
        subject = LoginItemState(
            cipherView: .loginFixture(
                fields: fields
            )
        )
        XCTAssertEqual(subject.properties.customFields, expectations)
    }

    /// A cipher with uris relays the properties.
    func test_init_success_uris_empty() {
        let uris: [BitwardenSdk.LoginUriView] = []
        subject = LoginItemState(
            cipherView: .loginFixture(
                login: .fixture(uris: uris)
            )
        )
        XCTAssertEqual(subject.properties.uris, [])
    }

    /// A cipher with uris relays the properties.
    func test_init_success_uris_some() {
        let uris: [LoginUriView] = [
            .init(uri: "jams", match: .domain),
        ]
        subject = LoginItemState(
            cipherView: .loginFixture(
                login: .fixture(uris: uris)
            )
        )
        XCTAssertEqual(
            subject.properties.uris,
            [
                .init(match: .domain, uri: "jams"),
            ]
        )
    }
}
