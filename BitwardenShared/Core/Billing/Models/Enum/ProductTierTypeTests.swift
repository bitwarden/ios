import XCTest

@testable import BitwardenShared

class ProductTierTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `isNotSelfUpgradable` returns `true` for tiers that cannot be upgraded by the user.
    func test_isNotSelfUpgradable_true() {
        XCTAssertTrue(ProductTierType.teams.isNotSelfUpgradable)
        XCTAssertTrue(ProductTierType.enterprise.isNotSelfUpgradable)
    }

    /// `isNotSelfUpgradable` returns `false` for tiers that can be upgraded by the user.
    func test_isNotSelfUpgradable_false() {
        XCTAssertFalse(ProductTierType.free.isNotSelfUpgradable)
        XCTAssertFalse(ProductTierType.families.isNotSelfUpgradable)
        XCTAssertFalse(ProductTierType.teamsStarter.isNotSelfUpgradable)
    }
}
