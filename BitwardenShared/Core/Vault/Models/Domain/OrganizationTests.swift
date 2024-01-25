import XCTest

@testable import BitwardenShared

class OrganizationTests: XCTestCase {
    // MARK: Tests

    /// `canManagePolicies` returns whether the user can manage policies for the organization.
    func test_canManagePolicies() {
        XCTAssertTrue(Organization.fixture(type: .admin).canManagePolicies)
        XCTAssertTrue(Organization.fixture(type: .owner).canManagePolicies)
        XCTAssertTrue(Organization.fixture(permissions: .fixture(managePolicies: true)).canManagePolicies)
        XCTAssertTrue(Organization.fixture(permissions: .fixture(managePolicies: true), type: .admin).canManagePolicies)

        XCTAssertFalse(Organization.fixture(type: .manager).canManagePolicies)
        XCTAssertFalse(Organization.fixture(type: .user).canManagePolicies)
    }

    /// `isAdmin` returns whether the user is can admin in the organization.
    func test_isAdmin() {
        XCTAssertTrue(Organization.fixture(type: .admin).isAdmin)
        XCTAssertTrue(Organization.fixture(type: .owner).isAdmin)

        XCTAssertFalse(Organization.fixture(type: .user).isAdmin)
        XCTAssertFalse(Organization.fixture(type: .manager).isAdmin)
        XCTAssertFalse(Organization.fixture(type: .custom).isAdmin)
    }

    /// `isExemptFromPolicies` returns whether the user is exempt from policies.
    func test_isExemptFromPolicies() {
        XCTAssertTrue(Organization.fixture(type: .admin).isExemptFromPolicies)
        XCTAssertTrue(Organization.fixture(type: .owner).isExemptFromPolicies)
        XCTAssertTrue(Organization.fixture(permissions: .fixture(managePolicies: true)).isExemptFromPolicies)
        XCTAssertTrue(
            Organization.fixture(permissions: .fixture(managePolicies: true), type: .admin).isExemptFromPolicies
        )

        XCTAssertFalse(Organization.fixture(type: .manager).isExemptFromPolicies)
        XCTAssertFalse(Organization.fixture(type: .user).isExemptFromPolicies)
    }
}
