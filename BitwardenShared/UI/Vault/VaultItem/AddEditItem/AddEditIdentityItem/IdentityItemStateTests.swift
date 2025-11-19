import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - IdentityItemStateTests

class IdentityItemStateTests: XCTestCase {
    // MARK: Tests

    /// `identity item state basic tests.
    func test_identity_state() {
        var subject = IdentityItemState()
        subject.title = .custom(.mr)
        subject.firstName = "first"
        subject.middleName = "middle"
        subject.lastName = "last"
        subject.userName = "user"
        subject.company = "company"
        subject.socialSecurityNumber = "socialSecurityNumber"
        subject.passportNumber = "passportNumber"
        subject.licenseNumber = "licenseNumber"
        subject.email = "email"
        subject.phone = "phone"
        subject.address1 = "address1"
        subject.address2 = "address2"
        subject.address3 = "address3"
        subject.cityOrTown = "cityOrTown"
        subject.state = "state"
        subject.postalCode = "postalCode"
        subject.country = "country"

        assertInlineSnapshot(of: subject, as: .dump) {
            """
            ▿ IdentityItemState
              - address1: "address1"
              - address2: "address2"
              - address3: "address3"
              - cityOrTown: "cityOrTown"
              - company: "company"
              - country: "country"
              - email: "email"
              - firstName: "first"
              - lastName: "last"
              - licenseNumber: "licenseNumber"
              - middleName: "middle"
              - passportNumber: "passportNumber"
              - phone: "phone"
              - postalCode: "postalCode"
              - socialSecurityNumber: "socialSecurityNumber"
              - state: "state"
              ▿ title: DefaultableType<TitleType>
                - custom: TitleType.mr
              - userName: "user"

            """
        }
    }

    /// `IdentityItemState` returns computed `identityName` value with all fields filled.
    func test_computedValue_identityName_full() {
        var subject = IdentityItemState()
        subject.title = .custom(.mr)
        subject.firstName = "First"
        subject.middleName = "Middle"
        subject.lastName = "Last"

        XCTAssertEqual(subject.identityName, "Mr First Middle Last")
    }

    /// `IdentityItemState` returns computed `identityName` value with all fields empty.
    func test_computedValue_identityName_empty() {
        var subject = IdentityItemState()
        subject.title = .default
        subject.firstName = "     "
        subject.middleName = "  "
        subject.lastName = ""

        XCTAssertEqual(subject.identityName, "")
    }

    /// `IdentityItemState` returns computed `identityName` value with partial fields empty.
    func test_computedValue_identityName_partial_empty() {
        var subject = IdentityItemState()
        subject.title = .custom(.dr)
        subject.firstName = "     "
        subject.middleName = "Middle"
        subject.lastName = ""

        XCTAssertEqual(subject.identityName, "Dr Middle")
    }

    /// `IdentityItemState` returns computed `fullAddress` value with all fields filled.
    func test_computedValue_fullAddress_full() {
        var subject = IdentityItemState()
        subject.address1 = "street 1"
        subject.address2 = "street 2"
        subject.address3 = "street 3"

        subject.cityOrTown = "City"
        subject.state = "State"
        subject.postalCode = "12345"
        subject.country = "USA"

        XCTAssertEqual(
            subject.fullAddress,
            """
            street 1
            street 2
            street 3
            City, State, 12345
            USA
            """,
        )
    }

    /// `IdentityItemState` returns computed `fullAddress` value with empty street addresses.
    func test_computedValue_fullAddress_emptyStreet() {
        var subject = IdentityItemState()
        subject.address1 = "   "
        subject.address2 = "   "
        subject.address3 = "    "

        subject.cityOrTown = "City"
        subject.state = "State"
        subject.postalCode = "12345"
        subject.country = "USA"

        XCTAssertEqual(
            subject.fullAddress,
            """
            City, State, 12345
            USA
            """,
        )
    }

    /// `IdentityItemState` returns computed `fullAddress` value with empty state addresses.
    func test_computedValue_fullAddress_emptyState() {
        var subject = IdentityItemState()
        subject.address1 = "street 1"
        subject.address2 = "  "
        subject.address3 = "street 3"

        subject.cityOrTown = "City"
        subject.postalCode = "12345"
        subject.country = "USA"

        XCTAssertEqual(
            subject.fullAddress,
            """
            street 1
            street 3
            City, 12345
            USA
            """,
        )
    }

    /// `IdentityItemState` returns computed `fullAddress` value with all fields empty.
    func test_computedValue_fullAddress_allEmpty() {
        var subject = IdentityItemState()
        subject.address1 = "   "
        subject.address2 = "   "
        subject.address3 = "    "

        subject.cityOrTown = " "
        subject.state = ""
        subject.postalCode = "  "
        subject.country = "  "

        XCTAssertEqual(subject.fullAddress, "")
    }

    /// `isContactInfoSectionEmpty` returns `false` if there are items to display in the contact info section.
    func test_isContactInfoSectionEmpty_false() {
        let subjectWithEmailAddress = IdentityItemState(email: "test@example.com")
        XCTAssertFalse(subjectWithEmailAddress.isContactInfoSectionEmpty)

        let subjectWithPhone = IdentityItemState(phone: "123-456-7890")
        XCTAssertFalse(subjectWithPhone.isContactInfoSectionEmpty)

        let subjectWithAddress = IdentityItemState(address1: "123 Main St.")
        XCTAssertFalse(subjectWithAddress.isContactInfoSectionEmpty)
    }

    /// `isContactInfoSectionEmpty` returns `true` if there are no items to display in the contact info section.
    func test_isContactInfoSectionEmpty_true() {
        let subject = IdentityItemState()
        XCTAssertTrue(subject.isContactInfoSectionEmpty)
    }

    /// `isIdentificationSectionEmpty` returns `false` if there are items to display in the identification section.
    func test_isIdentificationSectionEmpty_false() {
        let subjectWithSocialSecurityNumber = IdentityItemState(socialSecurityNumber: "1234567890")
        XCTAssertFalse(subjectWithSocialSecurityNumber.isIdentificationSectionEmpty)

        let subjectWithPassportNumber = IdentityItemState(passportNumber: "12345")
        XCTAssertFalse(subjectWithPassportNumber.isIdentificationSectionEmpty)

        let subjectWithLicenseNumber = IdentityItemState(licenseNumber: "ABC123")
        XCTAssertFalse(subjectWithLicenseNumber.isIdentificationSectionEmpty)
    }

    /// `isIdentificationSectionEmpty` returns `true` if there are no items to display in the identification section.
    func test_isIdentificationSectionEmpty_true() {
        let subject = IdentityItemState()
        XCTAssertTrue(subject.isIdentificationSectionEmpty)
    }

    /// `isPersonalDetailsSectionEmpty` returns `false` if there are items to display in the personal details section.
    func test_isPersonalDetailsSectionEmpty_false() {
        let subjectWithFirstName = IdentityItemState(firstName: "John")
        XCTAssertFalse(subjectWithFirstName.isPersonalDetailsSectionEmpty)

        let subjectWithLastName = IdentityItemState(lastName: "Doe")
        XCTAssertFalse(subjectWithLastName.isPersonalDetailsSectionEmpty)

        let subjectWithUsername = IdentityItemState(userName: "john")
        XCTAssertFalse(subjectWithUsername.isPersonalDetailsSectionEmpty)

        let subjectWithCompany = IdentityItemState(company: "Acme Inc.")
        XCTAssertFalse(subjectWithCompany.isPersonalDetailsSectionEmpty)
    }

    /// `isPersonalDetailsSectionEmpty` returns `true` if there are no items to display in the personal details section.
    func test_isPersonalDetailsSectionEmpty_true() {
        let subject = IdentityItemState()
        XCTAssertTrue(subject.isPersonalDetailsSectionEmpty)
    }
}
