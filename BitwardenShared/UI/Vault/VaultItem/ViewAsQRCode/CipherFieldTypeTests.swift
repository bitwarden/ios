import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - CipherFieldTypeTests

class CipherFieldTypeTests: BitwardenTestCase {
    /// `CipherView.value(.custom)` returns the custom field.
    func test_custom() {
        let cipher = CipherView.fixture(
            fields: [
                FieldView.fixture(name: "Test Field One", value: "Test Data One"),
                FieldView.fixture(name: "Test Field Two", value: "Test Data Two"),
            ]
        )

        XCTAssertEqual(CipherFieldType.custom(name: "Test Field One").localizedName, "Custom field: Test Field One")
        XCTAssertEqual(cipher.value(field: CipherFieldType.custom(name: "Test Field One")), "Test Data One")
        XCTAssertEqual(cipher.value(field: CipherFieldType.custom(name: "Test Field Two")), "Test Data Two")
        XCTAssertEqual(cipher.value(field: CipherFieldType.custom(name: "Test Field Three")), nil)
    }

    /// `CipherView.value(.name)` returns the item name.
    func test_name() {
        let cipher = CipherView.loginFixture(name: "Cipher Name")

        XCTAssertEqual(CipherFieldType.name.localizedName, Localizations.itemName)
        XCTAssertEqual(cipher.value(field: .name), "Cipher Name")
    }

    /// `CipherView.value(.none)` returns nil.
    func test_none() {
        let cipher = CipherView.loginFixture()

        XCTAssertEqual(CipherFieldType.none.localizedName, "--\(Localizations.select)--")
        XCTAssertEqual(cipher.value(field: .none), nil)
    }

    /// `CipherFieldType.notes` returns the notes.
    func test_notes() {
        let cipher = CipherView.loginFixture(notes: "Cipher Notes")

        XCTAssertEqual(CipherFieldType.notes.localizedName, Localizations.notes)
        XCTAssertEqual(cipher.value(field: .notes), "Cipher Notes")
    }

    /// `CipherView.value(.password)` returns the password.
    func test_password() {
        let cipher = CipherView.loginFixture(login: .fixture(password: "Cipher Password"))

        XCTAssertEqual(CipherFieldType.password.localizedName, Localizations.password)
        XCTAssertEqual(cipher.value(field: .password), "Cipher Password")
    }

    /// `CipherView.value(.uri)` returns the URL.
    func test_uri() {
        let cipher = CipherView.loginFixture(login: .fixture(uris: [
            .fixture(uri: "https://www.example.com/1"),
            .fixture(uri: "https://www.example.com/2"),
        ]))

        XCTAssertEqual(CipherFieldType.uri(index: 0).localizedName, Localizations.websiteURI)
        XCTAssertEqual(cipher.value(field: CipherFieldType.uri(index: 0)), "https://www.example.com/1")
        XCTAssertEqual(cipher.value(field: CipherFieldType.uri(index: 1)), "https://www.example.com/2")
        XCTAssertEqual(cipher.value(field: CipherFieldType.uri(index: 2)), nil)
    }

    /// `CipherView.value(.username)` returns the username.
    func test_username() {
        let cipher = CipherView.loginFixture(login: .fixture(username: "Cipher Username"))

        XCTAssertEqual(CipherFieldType.username.localizedName, Localizations.username)
        XCTAssertEqual(cipher.value(field: .username), "Cipher Username")
    }
}
