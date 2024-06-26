import BitwardenSdk
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
        XCTAssertNil(VaultListItem(cipherView: .fixture(id: nil)))
        XCTAssertNotNil(VaultListItem(cipherView: .fixture(id: ":)")))
    }

    /// `init` returns the expected value when using the one that takes `fido2CredentialAutofillView`.
    func test_init_fido2CredentialAutofillView() {
        XCTAssertNil(
            VaultListItem(
                cipherView: .fixture(id: nil),
                fido2CredentialAutofillView: .fixture()
            )
        )
        XCTAssertNil(
            VaultListItem(
                cipherView: .fixture(id: ":)", type: .card),
                fido2CredentialAutofillView: .fixture()
            )
        )
        XCTAssertNil(
            VaultListItem(
                cipherView: .fixture(id: ":)", type: .identity),
                fido2CredentialAutofillView: .fixture()
            )
        )
        XCTAssertNil(
            VaultListItem(
                cipherView: .fixture(id: ":)", type: .secureNote),
                fido2CredentialAutofillView: .fixture()
            )
        )
        XCTAssertNotNil(
            VaultListItem(
                cipherView: .fixture(id: ":)", type: .login),
                fido2CredentialAutofillView: .fixture()
            )
        )
    }

    /// `fido2CredentialRpId` returns expected value.
    func test_fido2CredentialRpId() { // swiftlint:disable:this function_body_length
        XCTAssertEqual(
            VaultListItem(
                cipherView: .fixture(
                    login: .fixture(
                        fido2Credentials: [
                            .fixture(),
                        ],
                        username: FakeData.username1
                    ),
                    name: "MyApp",
                    type: .login
                ),
                fido2CredentialAutofillView: .fixture(
                    userNameForUi: FakeData.username2
                )
            )!.fido2CredentialRpId,
            BitwardenSdk.Fido2CredentialAutofillView.defaultRpId
        )
        XCTAssertNil(
            VaultListItem(cipherView: .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(userName: FakeData.username2),
                    ],
                    username: FakeData.email1
                ),
                name: "MyApp",
                type: .login
            ))!.fido2CredentialRpId
        )
        XCTAssertNil(
            VaultListItem(cipherView: .fixture(
                login: .fixture(
                    username: FakeData.email1
                ),
                name: "MyApp",
                type: .login
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
            VaultListItem(cipherView: .fixture(type: .card))?.icon.name,
            Asset.Images.creditCard.name
        )
        XCTAssertEqual(
            VaultListItem(cipherView: .fixture(type: .identity))?.icon.name,
            Asset.Images.id.name
        )
        XCTAssertEqual(
            VaultListItem(cipherView: .fixture(type: .login))?.icon.name,
            Asset.Images.globe.name
        )
        XCTAssertEqual(
            VaultListItem(
                cipherView: .fixture(type: .login),
                fido2CredentialAutofillView: .fixture()
            )?.icon.name,
            Asset.Images.passkey.name
        )
        XCTAssertEqual(
            VaultListItem(cipherView: .fixture(type: .secureNote))?.icon.name,
            Asset.Images.doc.name
        )

        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.card, 1)).icon.name,
            Asset.Images.creditCard.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.collection(id: "", name: "", organizationId: "1"), 1)).icon.name,
            Asset.Images.collections.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.folder(id: "", name: ""), 1)).icon.name,
            Asset.Images.folderClosed.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.identity, 1)).icon.name,
            Asset.Images.id.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.login, 1)).icon.name,
            Asset.Images.globe.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.secureNote, 1)).icon.name,
            Asset.Images.doc.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.totp, 1)).icon.name,
            Asset.Images.clock.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.trash, 1)).icon.name,
            Asset.Images.trash.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.trash, 1)).icon.name,
            Asset.Images.trash.name
        )

        XCTAssertEqual(
            VaultListItem.fixtureTOTP(totp: .fixture()).icon.name,
            Asset.Images.clock.name
        )
    }

    /// `name` returns the expected value.
    func test_name() {
        XCTAssertEqual(subject.name, "")

        subject = .fixtureTOTP(totp: .fixture())
        XCTAssertEqual(subject.name, "Name123")
    }

    /// `shouldShowFido2CredentialRpId` returns expected value.
    func test_shouldShowFido2CredentialRpId() { // swiftlint:disable:this function_body_length
        XCTAssertTrue(
            VaultListItem(cipherView: .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(userName: FakeData.username2),
                    ],
                    username: FakeData.email1
                ),
                name: "MyApp",
                type: .login
            ), fido2CredentialAutofillView: .fixture())!.shouldShowFido2CredentialRpId
        )
        XCTAssertFalse(
            VaultListItem(cipherView: .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(userName: FakeData.username2),
                    ],
                    username: FakeData.email1
                ),
                name: BitwardenSdk.Fido2CredentialAutofillView.defaultRpId,
                type: .login
            ), fido2CredentialAutofillView: .fixture())!.shouldShowFido2CredentialRpId
        )
        XCTAssertFalse(
            VaultListItem(cipherView: .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(rpId: "", userName: FakeData.username2),
                    ],
                    username: FakeData.email1
                ),
                name: BitwardenSdk.Fido2CredentialAutofillView.defaultRpId,
                type: .login
            ), fido2CredentialAutofillView: .fixture())!.shouldShowFido2CredentialRpId
        )
        XCTAssertFalse(
            VaultListItem(cipherView: .fixture(
                login: .fixture(
                    username: FakeData.email1
                ),
                name: BitwardenSdk.Fido2CredentialAutofillView.defaultRpId,
                type: .login
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
            VaultListItem(cipherView: .fixture(
                card: .fixture(
                    brand: "Mom's Credit Card",
                    number: "1234567890"
                ),
                type: .card
            ))?.subtitle,
            "Mom's Credit Card, *7890"
        )

        XCTAssertEqual(
            VaultListItem(cipherView: .fixture(
                identity: .init(
                    title: nil,
                    firstName: "First",
                    middleName: nil,
                    lastName: "Last",
                    address1: nil,
                    address2: nil,
                    address3: nil,
                    city: nil,
                    state: nil,
                    postalCode: nil,
                    country: nil,
                    company: nil,
                    email: nil,
                    phone: nil,
                    ssn: nil,
                    username: nil,
                    passportNumber: nil,
                    licenseNumber: nil
                ),
                type: .identity
            ))?.subtitle,
            "First Last"
        )

        XCTAssertEqual(
            VaultListItem(cipherView: .fixture(
                login: .fixture(username: FakeData.email1),
                type: .login
            ))?.subtitle,
            FakeData.email1
        )

        XCTAssertNil(VaultListItem(cipherView: .fixture(type: .secureNote))?.subtitle)

        XCTAssertNil(VaultListItem(id: "1", itemType: .group(.card, 1)).subtitle)
        XCTAssertNil(VaultListItem.fixtureTOTP(totp: .fixture()).subtitle)
    }

    /// `subtitle` returns the expected value when in Fido2 credential.
    func test_subtitle_fido2() {
        XCTAssertEqual(
            VaultListItem(cipherView: .fixture(
                login: .fixture(
                    fido2Credentials: [
                        .fixture(),
                    ],
                    username: FakeData.email1
                ),
                type: .login
            ), fido2CredentialAutofillView: .fixture(userNameForUi: FakeData.username2))?.subtitle,
            FakeData.username2
        )
    }
}

private extension BitwardenSdk.LoginView {
    static func usernameFixture() -> BitwardenSdk.LoginView {
        .fixture(username: FakeData.email1)
    }
}
