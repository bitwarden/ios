import XCTest

import BitwardenResources
@testable import BitwardenShared

class CipherTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:allowedFieldTypes` return the correct `FielldType` array for the given cipher type..
    func test_allowedFieldTypes() {
        XCTAssertEqual(CipherType.login.allowedFieldTypes, [.text, .hidden, .boolean, .linked])
        XCTAssertEqual(CipherType.card.allowedFieldTypes, [.text, .hidden, .boolean, .linked])
        XCTAssertEqual(CipherType.identity.allowedFieldTypes, [.text, .hidden, .boolean, .linked])
        XCTAssertEqual(CipherType.secureNote.allowedFieldTypes, [.text, .hidden, .boolean])
        XCTAssertEqual(CipherType.sshKey.allowedFieldTypes, [.text, .hidden, .boolean])
        XCTAssertEqual(CipherType.bankAccount.allowedFieldTypes, [.text, .hidden, .boolean])
    }

    /// `localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(CipherType.card.localizedName, Localizations.typeCard)
        XCTAssertEqual(CipherType.identity.localizedName, Localizations.typeIdentity)
        XCTAssertEqual(CipherType.login.localizedName, Localizations.typeLogin)
        XCTAssertEqual(CipherType.secureNote.localizedName, Localizations.typeSecureNote)
        XCTAssertEqual(CipherType.sshKey.localizedName, Localizations.sshKey)
        XCTAssertEqual(CipherType.bankAccount.localizedName, Localizations.typeBankAccount)
    }

    /// `init` with a `VaultListGroup` produces the correct value.
    ///
    /// - Note: The `.bankAccount` group case is introduced in PM-32809 Part 2/3, at
    ///   which point a matching `XCTAssertEqual(CipherType(group: .bankAccount),
    ///   .bankAccount)` assertion will be added here.
    func test_init_group() {
        XCTAssertEqual(CipherType(group: .card), .card)
        XCTAssertNil(CipherType(group: .collection(id: "id", name: "name", organizationId: "1")))
        XCTAssertNil(CipherType(group: .folder(id: "id", name: "name")))
        XCTAssertEqual(CipherType(group: .identity), .identity)
        XCTAssertEqual(CipherType(group: .login), .login)
        XCTAssertEqual(CipherType(group: .secureNote), .secureNote)
        XCTAssertEqual(CipherType(group: .sshKey), .sshKey)
        XCTAssertNil(CipherType(group: .archive))
        XCTAssertNil(CipherType(group: .trash))
    }

    /// `canCreateCasesBase` preserves today's flag-off creation set.
    func test_canCreateCasesBase() {
        XCTAssertEqual(CipherType.canCreateCasesBase, [.login, .card, .identity, .secureNote])
    }

    /// `canCreateCasesWithNewItemTypes` extends the base set with the PM-32009 types.
    func test_canCreateCasesWithNewItemTypes() {
        XCTAssertEqual(
            CipherType.canCreateCasesWithNewItemTypes,
            [.login, .card, .identity, .secureNote, .bankAccount],
        )
    }

    /// `canCreateCases(isNewItemTypesEnabled:)` returns the base set when the flag is off and
    /// adds Bank Account when the flag is on.
    func test_canCreateCases_withFlag() {
        XCTAssertEqual(
            CipherType.canCreateCases(isNewItemTypesEnabled: false),
            [.login, .card, .identity, .secureNote],
        )
        XCTAssertEqual(
            CipherType.canCreateCases(isNewItemTypesEnabled: true),
            [.login, .card, .identity, .secureNote, .bankAccount],
        )
        // The flag-off list never contains `.bankAccount`.
        XCTAssertFalse(CipherType.canCreateCases(isNewItemTypesEnabled: false).contains(.bankAccount))
    }

    /// `allCases` returns every app-layer cipher type in a stable order.
    func test_allCases() {
        XCTAssertEqual(
            CipherType.allCases,
            [.login, .card, .identity, .secureNote, .sshKey, .bankAccount],
        )
    }
}
