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
}
