import BitwardenKitMocks
import XCTest

@testable import BitwardenKit

final class FeatureFlagTests: BitwardenTestCase {
    // MARK: Tests

    /// `name` formats the raw value of a feature flag
    func test_name() {
        XCTAssertEqual(FeatureFlag.testFeatureFlag.name, "Test Feature Flag")
        XCTAssertEqual(FeatureFlag.testInitialBoolFlag.name, "Test Initial Bool Flag")
        XCTAssertEqual(FeatureFlag.testInitialIntFlag.name, "Test Initial Int Flag")
        XCTAssertEqual(FeatureFlag.testInitialStringFlag.name, "Test Initial String Flag")
    }
}
