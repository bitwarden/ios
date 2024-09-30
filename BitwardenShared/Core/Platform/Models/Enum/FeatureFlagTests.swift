import XCTest

@testable import BitwardenShared

final class FeatureFlagTests: BitwardenTestCase {
    // MARK: Tests

    /// `debugMenuFeatureFlags` does not include any test flags
    func test_debugMenu_testFlags() {
        let actual = FeatureFlag.debugMenuFeatureFlags.map(\.rawValue)
        let filtered = actual.filter { $0.hasPrefix("test-") }
        XCTAssertEqual(filtered, [])
    }

    /// `name` formats the raw value of a feature flag
    func test_name() {
        XCTAssertEqual(FeatureFlag.testLocalFeatureFlag.name, "Test Local Feature Flag")
        XCTAssertEqual(FeatureFlag.testInitialBoolFlag.name, "Test Initial Bool Flag")
        XCTAssertEqual(FeatureFlag.testInitialIntFlag.name, "Test Initial Int Flag")
        XCTAssertEqual(FeatureFlag.testInitialStringFlag.name, "Test Initial String Flag")
    }
}
