import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

class VaultListItemTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var subject: VaultListItem!

    override func setUp() {
        super.setUp()

        subject = .fixture()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `init` returns the expected value.
    func test_init() {
        XCTAssertNil(VaultListItem(cipherListView: .fixture(id: nil)))
        XCTAssertNotNil(VaultListItem(cipherListView: .fixture(id: ":)")))
    }

    /// `init` returns the expected value when using the one that takes `fido2CredentialAutofillView`.
    func test_init_fido2CredentialAutofillView() {
        XCTAssertNil(
            VaultListItem(
                cipherListView: .fixture(id: nil),
                fido2CredentialAutofillView: .fixture()
            )
        )
        XCTAssertNil(
            VaultListItem(
                cipherListView: .fixture(id: ":)", type: .card(.init(brand: nil))),
                fido2CredentialAutofillView: .fixture()
            )
        )
        XCTAssertNil(
            VaultListItem(
                cipherListView: .fixture(id: ":)", type: .identity),
                fido2CredentialAutofillView: .fixture()
            )
        )
        XCTAssertNil(
            VaultListItem(
                cipherListView: .fixture(id: ":)", type: .secureNote),
                fido2CredentialAutofillView: .fixture()
            )
        )
        XCTAssertNotNil(
            VaultListItem(
                cipherListView: .fixture(id: ":)", login: .fixture()),
                fido2CredentialAutofillView: .fixture()
            )
        )
    }

    /// `fido2CredentialRpId` returns expected value.
    func test_fido2CredentialRpId() {
        XCTAssertEqual(
            VaultListItem(
                cipherListView: .fixture(
                    login: .fixture(
                        fido2Credentials: [
                            .fixture(),
                        ],
                        username: FakeData.username1
                    ),
                    name: "MyApp"
                ),
                fido2CredentialAutofillView: .fixture(
                    userNameForUi: FakeData.username2
                )
            )!.fido2CredentialRpId,
            BitwardenSdk.Fido2CredentialAutofillView.defaultRpId
        )
        XCTAssertNil(
            VaultListItem(cipherListView: .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(userName: FakeData.username2),
                    ],
                    username: FakeData.email1
                ),
                name: "MyApp"
            ))!.fido2CredentialRpId
        )
        XCTAssertNil(
            VaultListItem(cipherListView: .fixture(
                login: .fixture(
                    username: FakeData.email1
                ),
                name: "MyApp"
            ))!.fido2CredentialRpId
        )
        XCTAssertNil(
            VaultListItem(
                id: "1",
                itemType: .group(.card, 1)
            ).fido2CredentialRpId
        )
        XCTAssertNil(
            VaultListItem(
                id: "1",
                itemType: .totp(name: "test", totpModel: VaultListTOTP.fixture())
            ).fido2CredentialRpId
        )
    }

    /// `icon` returns the expected value.
    func test_icon() { // swiftlint:disable:this function_body_length
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(type: .card(.init(brand: nil))))?.icon.name,
            Asset.Images.card24.name
        )
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(type: .identity))?.icon.name,
            Asset.Images.idCard24.name
        )
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(login: .fixture()))?.icon.name,
            Asset.Images.globe24.name
        )
        XCTAssertEqual(
            VaultListItem(
                cipherListView: .fixture(login: .fixture()),
                fido2CredentialAutofillView: .fixture()
            )?.icon.name,
            Asset.Images.passkey24.name
        )
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(type: .secureNote))?.icon.name,
            Asset.Images.file24.name
        )
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(type: .sshKey))?.icon.name,
            Asset.Images.key24.name
        )

        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.card, 1)).icon.name,
            Asset.Images.card24.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.collection(id: "", name: "", organizationId: "1"), 1)).icon.name,
            Asset.Images.collections24.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.folder(id: "", name: ""), 1)).icon.name,
            Asset.Images.folder24.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.identity, 1)).icon.name,
            Asset.Images.idCard24.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.login, 1)).icon.name,
            Asset.Images.globe24.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.secureNote, 1)).icon.name,
            Asset.Images.file24.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.sshKey, 1)).icon.name,
            Asset.Images.key24.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.totp, 1)).icon.name,
            Asset.Images.clock24.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.trash, 1)).icon.name,
            Asset.Images.trash24.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.trash, 1)).icon.name,
            Asset.Images.trash24.name
        )

        XCTAssertEqual(
            VaultListItem.fixtureTOTP(totp: .fixture()).icon.name,
            Asset.Images.clock24.name
        )
    }

    /// `getter:iconAccessibilityId` gets the appropriate id for each icon.
    func test_iconAccessibilityId() {
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(type: .card(.init(brand: nil))))?.iconAccessibilityId,
            "CardCipherIcon"
        )
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(type: .identity))?.iconAccessibilityId,
            "IdentityCipherIcon"
        )
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(login: .fixture()))?.iconAccessibilityId,
            "LoginCipherIcon"
        )
        XCTAssertEqual(
            VaultListItem(
                cipherListView: .fixture(login: .fixture()),
                fido2CredentialAutofillView: .fixture()
            )?.iconAccessibilityId,
            "LoginCipherIcon"
        )
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(type: .secureNote))?.iconAccessibilityId,
            "SecureNoteCipherIcon"
        )
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(type: .sshKey))?.iconAccessibilityId,
            "SSHKeyCipherIcon"
        )

        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.card, 1)).iconAccessibilityId,
            ""
        )

        XCTAssertEqual(
            VaultListItem.fixtureTOTP(totp: .fixture()).iconAccessibilityId,
            ""
        )
    }

    /// `getter:vaultItemAccessibilityId` gets the appropriate id for each vault item.
    func test_vaultItemAccessibilityId() { // swiftlint:disable:this function_body_length
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(login: .fixture()))?.vaultItemAccessibilityId,
            "CipherCell"
        )
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(type: .card(.init(brand: nil))))?.vaultItemAccessibilityId,
            "CipherCell"
        )
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(type: .identity))?.vaultItemAccessibilityId,
            "CipherCell"
        )
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(type: .secureNote))?.vaultItemAccessibilityId,
            "CipherCell"
        )
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(type: .sshKey))?.vaultItemAccessibilityId,
            "CipherCell"
        )

        XCTAssertEqual(
            VaultListItem.fixtureTOTP(totp: .fixture()).vaultItemAccessibilityId,
            "TOTPCell"
        )

        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.collection(id: "", name: "", organizationId: "1"), 1))
                .vaultItemAccessibilityId,
            "CollectionCell"
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.folder(id: "", name: ""), 1)).vaultItemAccessibilityId,
            "FolderCell"
        )

        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.login, 1)).vaultItemAccessibilityId,
            "ItemFilterCell"
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.card, 1)).vaultItemAccessibilityId,
            "ItemFilterCell"
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.identity, 1)).vaultItemAccessibilityId,
            "ItemFilterCell"
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.secureNote, 1)).vaultItemAccessibilityId,
            "ItemFilterCell"
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.sshKey, 1)).vaultItemAccessibilityId,
            "ItemFilterCell"
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.totp, 1)).vaultItemAccessibilityId,
            "ItemFilterCell"
        )
    }

    /// `sortValue` returns the expected value.
    func test_sortValue() {
        subject = .fixture(cipherListView: .fixture(name: "CipherName"))
        XCTAssertEqual(subject.sortValue, "CipherName")

        subject = .fixtureGroup()
        XCTAssertEqual(subject.sortValue, "")

        subject = .fixtureTOTP(totp: .fixture())
        XCTAssertEqual(subject.sortValue, "Name123")
    }

    /// `shouldShowFido2CredentialRpId` returns expected value.
    func test_shouldShowFido2CredentialRpId() {
        XCTAssertTrue(
            VaultListItem(cipherListView: .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(userName: FakeData.username2),
                    ],
                    username: FakeData.email1
                ),
                name: "MyApp"
            ), fido2CredentialAutofillView: .fixture())!.shouldShowFido2CredentialRpId
        )
        XCTAssertFalse(
            VaultListItem(cipherListView: .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(userName: FakeData.username2),
                    ],
                    username: FakeData.email1
                ),
                name: BitwardenSdk.Fido2CredentialAutofillView.defaultRpId
            ), fido2CredentialAutofillView: .fixture())!.shouldShowFido2CredentialRpId
        )
        XCTAssertFalse(
            VaultListItem(cipherListView: .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(rpId: "", userName: FakeData.username2),
                    ],
                    username: FakeData.email1
                ),
                name: BitwardenSdk.Fido2CredentialAutofillView.defaultRpId
            ), fido2CredentialAutofillView: .fixture())!.shouldShowFido2CredentialRpId
        )
        XCTAssertFalse(
            VaultListItem(cipherListView: .fixture(
                login: .fixture(
                    username: FakeData.email1
                ),
                name: BitwardenSdk.Fido2CredentialAutofillView.defaultRpId
            ))!.shouldShowFido2CredentialRpId
        )
        XCTAssertFalse(
            VaultListItem(id: "1", itemType: .group(.card, 1)).shouldShowFido2CredentialRpId
        )
        XCTAssertFalse(
            VaultListItem(
                id: "1",
                itemType: .totp(name: "test", totpModel: VaultListTOTP.fixture())
            ).shouldShowFido2CredentialRpId
        )
    }

    /// `subtitle` returns the expected value.
    func test_subtitle() {
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(
                subtitle: "Mom's Credit Card, *7890",
                type: .card(.init(brand: nil))
            ))?.subtitle,
            "Mom's Credit Card, *7890"
        )

        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(
                subtitle: "First Last",
                type: .identity
            ))?.subtitle,
            "First Last"
        )

        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(
                login: .fixture(username: FakeData.email1),
                subtitle: FakeData.email1
            ))?.subtitle,
            FakeData.email1
        )

        XCTAssertEqual(VaultListItem(cipherListView: .fixture(type: .secureNote))?.subtitle, "")
        XCTAssertEqual(VaultListItem(cipherListView: .fixture(type: .sshKey))?.subtitle, "")

        XCTAssertNil(VaultListItem(id: "1", itemType: .group(.card, 1)).subtitle)
        XCTAssertNil(VaultListItem.fixtureTOTP(totp: .fixture()).subtitle)
    }

    /// `subtitle` returns the expected value when in Fido2 credential.
    func test_subtitle_fido2() {
        XCTAssertEqual(
            VaultListItem(cipherListView: .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(),
                    ],
                    username: FakeData.email1
                )
            ), fido2CredentialAutofillView: .fixture(userNameForUi: FakeData.username2))?.subtitle,
            FakeData.username2
        )
    }
}

private extension BitwardenSdk.LoginView {
    static func usernameFixture() -> BitwardenSdk.LoginView {
        .fixture(username: FakeData.email1)
    }
} // swiftlint:disable:this file_length
