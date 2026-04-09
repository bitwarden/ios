import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class VaultListSectionTests: BitwardenTestCase {
    // MARK: Tests

    /// `hasLoginItems` returns `false` if there's no login items within the sections.
    func test_vaultListSectionArray_hasLoginItems_false() {
        let subjectEmpty = [VaultListSection]()
        XCTAssertFalse(subjectEmpty.hasLoginItems)

        let subjectWithoutLogin = [
            VaultListSection(id: "2", items: [.fixtureGroup(group: .card, count: 2)], name: "Cards"),
            VaultListSection(id: "3", items: [.fixtureGroup(group: .identity, count: 3)], name: "Identities"),
            VaultListSection(id: "4", items: [.fixtureGroup(group: .secureNote, count: 0)], name: "Notes"),
        ]
        XCTAssertFalse(subjectWithoutLogin.hasLoginItems)

        let subjectLoginsEmpty = [
            VaultListSection(id: "1", items: [.fixtureGroup(group: .login, count: 0)], name: "Logins"),
            VaultListSection(id: "2", items: [.fixtureGroup(group: .card, count: 2)], name: "Cards"),
            VaultListSection(id: "3", items: [.fixtureGroup(group: .identity, count: 3)], name: "Identities"),
            VaultListSection(id: "4", items: [.fixtureGroup(group: .secureNote, count: 0)], name: "Notes"),
        ]
        XCTAssertFalse(subjectLoginsEmpty.hasLoginItems)

        let subjectCiphersNoLogins = [
            VaultListSection(id: "5", items: [.fixture(cipherListView: .fixture(type: .identity))], name: "Items"),
        ]
        XCTAssertFalse(subjectCiphersNoLogins.hasLoginItems)
    }

    /// `hasLoginItems` returns `true` if there's a login group with more than one item or a login
    /// cipher within the sections.
    func test_vaultListSectionArray_hasLoginItems_true() {
        let subjectWithLogin = [
            VaultListSection(id: "1", items: [.fixtureGroup(group: .login, count: 1)], name: "Logins"),
        ]
        XCTAssertTrue(subjectWithLogin.hasLoginItems)

        let subjectWithMultipleSections = [
            VaultListSection(id: "1", items: [.fixtureGroup(group: .login, count: 1)], name: "Logins"),
            VaultListSection(id: "2", items: [.fixtureGroup(group: .card, count: 2)], name: "Cards"),
            VaultListSection(id: "3", items: [.fixtureGroup(group: .identity, count: 3)], name: "Identities"),
            VaultListSection(id: "4", items: [.fixtureGroup(group: .secureNote, count: 0)], name: "Notes"),
        ]
        XCTAssertTrue(subjectWithMultipleSections.hasLoginItems)

        let subjectWithCipher = [
            VaultListSection(id: "2", items: [.fixtureGroup(group: .card, count: 2)], name: "Cards"),
            VaultListSection(
                id: "5",
                items: [
                    .fixture(cipherListView: .fixture(login: .fixture())),
                ],
                name: "Items",
            ),
        ]
        XCTAssertTrue(subjectWithCipher.hasLoginItems)

        let subjectWithTOTP = [
            VaultListSection(id: "1", items: [.fixtureTOTP(totp: .fixture())], name: "TOTP"),
        ]
        XCTAssertTrue(subjectWithTOTP.hasLoginItems)

        let subjectWithTOTPGroup = [
            VaultListSection(id: "2", items: [.fixtureGroup(group: .totp, count: 2)], name: "TOTP"),
        ]
        XCTAssertTrue(subjectWithTOTPGroup.hasLoginItems)
    }
}
