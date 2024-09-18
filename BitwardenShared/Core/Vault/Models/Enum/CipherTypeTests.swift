import XCTest

@testable import BitwardenShared

class CipherTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(CipherType.card.localizedName, Localizations.typeCard)
        XCTAssertEqual(CipherType.identity.localizedName, Localizations.typeIdentity)
        XCTAssertEqual(CipherType.login.localizedName, Localizations.typeLogin)
        XCTAssertEqual(CipherType.secureNote.localizedName, Localizations.typeSecureNote)
    }

    /// `init` with a `VaultListGroup` produces the correct value.
    func test_init_group() {
        XCTAssertEqual(CipherType(group: .card), .card)
        XCTAssertNil(CipherType(group: .collection(id: "id", name: "name", organizationId: "1")))
        XCTAssertNil(CipherType(group: .folder(id: "id", name: "name")))
        XCTAssertEqual(CipherType(group: .identity), .identity)
        XCTAssertEqual(CipherType(group: .login), .login)
        XCTAssertEqual(CipherType(group: .secureNote), .secureNote)
        XCTAssertNil(CipherType(group: .trash))
    }

    /// `canCreateCases` return the correct cipher types that the user can use to create ciphers.
    func test_canCreateCases() {
        XCTAssertEqual(CipherType.canCreateCases, [.login, .card, .identity, .secureNote])
    }
}
