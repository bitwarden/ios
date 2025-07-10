import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - CipherListViewExtensionsTests

class CipherListViewExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `passesRestrictItemTypesPolicy(_:)` passes the policy when there are no organization IDs.
    func test_passesRestrictItemTypesPolicy_noOrgIds() {
        XCTAssertTrue(CipherListView.fixture().passesRestrictItemTypesPolicy([]))
    }

    /// `passesRestrictItemTypesPolicy(_:)` passes the policy when the cipher type is not `.card`.
    func test_passesRestrictItemTypesPolicy_noCardType() {
        XCTAssertTrue(CipherListView.fixture(type: .login(.fixture())).passesRestrictItemTypesPolicy(["1"]))
        XCTAssertTrue(CipherListView.fixture(type: .identity).passesRestrictItemTypesPolicy(["1"]))
        XCTAssertTrue(CipherListView.fixture(type: .secureNote).passesRestrictItemTypesPolicy(["1"]))
        XCTAssertTrue(CipherListView.fixture(type: .sshKey).passesRestrictItemTypesPolicy(["1"]))
    }

    /// `passesRestrictItemTypesPolicy(_:)` doesn't pass the policy when there are organization IDs,
    /// cipher type is `.card` but cipher doesn't belong to an organization or such organization has empty ID.
    func test_passesRestrictItemTypesPolicy_noCipherOrganizationId() {
        XCTAssertFalse(
            CipherListView.fixture(organizationId: nil, type: .card(.fixture())).passesRestrictItemTypesPolicy(["1"])
        )
        XCTAssertFalse(
            CipherListView.fixture(organizationId: "", type: .card(.fixture())).passesRestrictItemTypesPolicy(["1"])
        )
    }

    /// `passesRestrictItemTypesPolicy(_:)` doesn't pass the policy when there are organization IDs,
    /// cipher type is `.card`, cipher belongs to an organization but it's part of the restricted IDs.
    func test_passesRestrictItemTypesPolicy_restrictedOrganizationId() {
        XCTAssertFalse(
            CipherListView.fixture(organizationId: "2", type: .card(.fixture()))
                .passesRestrictItemTypesPolicy(["1", "2", "3"])
        )
    }

    /// `passesRestrictItemTypesPolicy(_:)` pass the policy when there are organization IDs,
    /// cipher type is `.card`, cipher belongs to an organization that isn't part of the restricted IDs.
    func test_passesRestrictItemTypesPolicy_passOnNonRestrictedOrganizationId() {
        XCTAssertTrue(
            CipherListView.fixture(organizationId: "5", type: .card(.fixture()))
                .passesRestrictItemTypesPolicy(["1", "2", "3"])
        )
    }
}
