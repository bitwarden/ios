import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - CipherFieldTypeTests

class CipherFieldTypeTests: BitwardenTestCase {
    // MARK: CipherView.availableFields

    /// `CipherView.availableFields` always has name, even if there are no other fields
    func test_availableFields_empty() {
        let cipher = CipherView.fixture()

        XCTAssertEqual(cipher.availableFields, [.name])
    }

    /// `CipherView.availableFields` includes fields.
    func test_availableFields_full() {
        let cipher = CipherView.fixture(
            fields: [
                .fixture(name: "Test Field One"),
                .fixture(name: "Test Field Two"),
            ],
            login: .fixture(
                password: "Test Password",
                uris: [
                    .fixture(),
                    .fixture(),
                ],
                username: "Test Username"
            ),
            notes: "Test Notes"
        )

        XCTAssertEqual(
            cipher.availableFields,
            [
                .name,
                .username,
                .password,
                .notes,
                .uri(index: 0),
                .uri(index: 1),
                .custom(name: "Test Field One"),
                .custom(name: "Test Field Two"),
            ]
        )
    }

    // MARK: CipherView.value(of:)

    /// `CipherView.value(.custom)` returns the custom field.
    func test_value_custom() {
        let cipher = CipherView.fixture(
            fields: [
                FieldView.fixture(name: "Test Field One", value: "Test Data One"),
                FieldView.fixture(name: "Test Field Two", value: "Test Data Two"),
            ]
        )

        XCTAssertEqual(CipherFieldType.custom(name: "Test Field One").localizedName, "Custom field: Test Field One")
        XCTAssertEqual(cipher.value(of: CipherFieldType.custom(name: "Test Field One")), "Test Data One")
        XCTAssertEqual(cipher.value(of: CipherFieldType.custom(name: "Test Field Two")), "Test Data Two")
        XCTAssertEqual(cipher.value(of: CipherFieldType.custom(name: "Test Field Three")), nil)
    }

    /// `CipherView.value(.name)` returns the item name.
    func test_value_name() {
        let cipher = CipherView.loginFixture(name: "Cipher Name")

        XCTAssertEqual(CipherFieldType.name.localizedName, Localizations.itemName)
        XCTAssertEqual(cipher.value(of: .name), "Cipher Name")
    }

    /// `CipherView.value(.none)` returns nil.
    func test_value_none() {
        let cipher = CipherView.loginFixture()

        XCTAssertEqual(CipherFieldType.none.localizedName, "--\(Localizations.select)--")
        XCTAssertEqual(cipher.value(of: .none), nil)
    }

    /// `CipherFieldType.notes` returns the notes.
    func test_value_notes() {
        let cipher = CipherView.loginFixture(notes: "Cipher Notes")

        XCTAssertEqual(CipherFieldType.notes.localizedName, Localizations.notes)
        XCTAssertEqual(cipher.value(of: .notes), "Cipher Notes")
    }

    /// `CipherView.value(.password)` returns the password.
    func test_value_password() {
        let cipher = CipherView.loginFixture(login: .fixture(password: "Cipher Password"))

        XCTAssertEqual(CipherFieldType.password.localizedName, Localizations.password)
        XCTAssertEqual(cipher.value(of: .password), "Cipher Password")
    }

    /// `CipherView.value(.uri)` returns the URL.
    func test_value_uri() {
        let cipher = CipherView.loginFixture(login: .fixture(uris: [
            .fixture(uri: "https://www.example.com/1"),
            .fixture(uri: "https://www.example.com/2"),
        ]))

        XCTAssertEqual(CipherFieldType.uri(index: 0).localizedName, Localizations.websiteURI)
        XCTAssertEqual(cipher.value(of: CipherFieldType.uri(index: 0)), "https://www.example.com/1")
        XCTAssertEqual(cipher.value(of: CipherFieldType.uri(index: 1)), "https://www.example.com/2")
        XCTAssertEqual(cipher.value(of: CipherFieldType.uri(index: 2)), nil)
    }

    /// `CipherView.value(.username)` returns the username.
    func test_value_username() {
        let cipher = CipherView.loginFixture(login: .fixture(username: "Cipher Username"))

        XCTAssertEqual(CipherFieldType.username.localizedName, Localizations.username)
        XCTAssertEqual(cipher.value(of: .username), "Cipher Username")
    }
}
