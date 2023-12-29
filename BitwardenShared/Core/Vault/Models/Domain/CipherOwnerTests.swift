import XCTest

@testable import BitwardenShared

class CipherOwnerTests: XCTestCase {
    // MARK: Tests

    /// `localizedName` returns the name value displayed in the menu.
    func test_localizedName() {
        XCTAssertEqual(CipherOwner.organization(id: "1", name: "Organization").localizedName, "Organization")
        XCTAssertEqual(CipherOwner.organization(id: "2", name: "Org 2").localizedName, "Org 2")
        XCTAssertEqual(CipherOwner.personal(email: "user@bitwarden").localizedName, "user@bitwarden")
    }

    /// `OwnerType.isPersonal` returns whether the owner type is a personal owner.
    func test_isPersonal() {
        XCTAssertFalse(CipherOwner.organization(id: "1", name: "Organization").isPersonal)
        XCTAssertTrue(CipherOwner.personal(email: "user@bitwarden.com").isPersonal)
    }

    /// `OwnerType.organizationId` returns the organization ID of an organization owner.
    func test_organizationId() {
        XCTAssertEqual(CipherOwner.organization(id: "1", name: "Organization").organizationId, "1")
        XCTAssertEqual(CipherOwner.organization(id: "2", name: "Organization").organizationId, "2")
        XCTAssertNil(CipherOwner.personal(email: "user@bitwarden.com").organizationId)
    }
}
