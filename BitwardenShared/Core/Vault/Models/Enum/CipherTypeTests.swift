import XCTest

@testable import BitwardenShared

class CipherTypeTests: BitwardenTestCase {
    // MARK: Tests

    func test_localizedName() {
        XCTAssertEqual(CipherType.card.localizedName, Localizations.typeCard)
        XCTAssertEqual(CipherType.identity.localizedName, Localizations.typeIdentity)
        XCTAssertEqual(CipherType.login.localizedName, Localizations.typeLogin)
        XCTAssertEqual(CipherType.secureNote.localizedName, Localizations.typeSecureNote)
    }

    func test_init_group() {
        XCTAssertNil(CipherType(group: nil))
        XCTAssertEqual(CipherType(group: .card), .card)
        XCTAssertNil(CipherType(group: .folder(id: "id", name: "name")))
        XCTAssertEqual(CipherType(group: .identity), .identity)
        XCTAssertEqual(CipherType(group: .login), .login)
        XCTAssertEqual(CipherType(group: .secureNote), .secureNote)
        XCTAssertNil(CipherType(group: .trash))
    }
}
