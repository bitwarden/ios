import XCTest

@testable import BitwardenShared

class VaultListItemTests: BitwardenTestCase {
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
            VaultListItem(cipherView: .fixture(type: .secureNote))?.icon.name,
            Asset.Images.doc.name
        )

        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.card, 1)).icon.name,
            Asset.Images.creditCard.name
        )
        XCTAssertEqual(
            VaultListItem(id: "", itemType: .group(.collection(id: "", name: ""), 1)).icon.name,
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
            VaultListItem.fixtureTOTP().icon.name,
            Asset.Images.clock.name
        )
    }

    /// `name` returns the expected value.
    func test_name() {
        XCTAssertEqual(subject.name, "")

        subject = .fixtureTOTP()
        XCTAssertEqual(subject.name, "Name123")
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
                login: .fixture(username: "email@example.com"),
                type: .login
            ))?.subtitle,
            "email@example.com"
        )

        XCTAssertNil(VaultListItem(cipherView: .fixture(type: .secureNote))?.subtitle)

        XCTAssertNil(VaultListItem(id: "1", itemType: .group(.card, 1)).subtitle)
        XCTAssertNil(VaultListItem.fixtureTOTP().subtitle)
    }
}
