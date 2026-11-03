import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class OrganizationTests: XCTestCase {
    // MARK: Tests

    /// `canManagePolicies` returns whether the user can manage policies for the organization.
    func test_canManagePolicies() {
        XCTAssertTrue(Organization.fixture(type: .admin).canManagePolicies)
        XCTAssertTrue(Organization.fixture(type: .owner).canManagePolicies)
        XCTAssertTrue(Organization.fixture(permissions: .fixture(managePolicies: true)).canManagePolicies)
        XCTAssertTrue(Organization.fixture(permissions: .fixture(managePolicies: true), type: .admin).canManagePolicies)

        XCTAssertFalse(Organization.fixture(type: .custom).canManagePolicies)
        XCTAssertFalse(Organization.fixture(type: .user).canManagePolicies)
    }

    /// `isAdmin` returns whether the user is can admin in the organization.
    func test_isAdmin() {
        XCTAssertTrue(Organization.fixture(type: .admin).isAdmin)
        XCTAssertTrue(Organization.fixture(type: .owner).isAdmin)

        XCTAssertFalse(Organization.fixture(type: .user).isAdmin)
        XCTAssertFalse(Organization.fixture(type: .custom).isAdmin)
    }
}
