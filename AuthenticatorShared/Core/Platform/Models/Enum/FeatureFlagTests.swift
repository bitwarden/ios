import XCTest

@testable import AuthenticatorShared

final class FeatureFlagTests: AuthenticatorTestCase {
    // MARK: Tests

    /// `debugMenuFeatureFlags` does not include any test flags
    func test_debugMenu_testFlags() {
        let actual = FeatureFlag.debugMenuFeatureFlags.map(\.rawValue)
        let filtered = actual.filter { $0.hasPrefix("test-") }
        XCTAssertEqual(filtered, [])
    }

    /// `isRemotelyConfigured` returns the correct value for each flag.
    func test_isRemotelyConfigured() {
        XCTAssertTrue(FeatureFlag.enablePasswordManagerSync.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.testRemoteFeatureFlag.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.testRemoteInitialBoolFlag.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.testRemoteInitialIntFlag.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.testRemoteInitialStringFlag.isRemotelyConfigured)

        XCTAssertFalse(FeatureFlag.testLocalFeatureFlag.isRemotelyConfigured)
        XCTAssertFalse(FeatureFlag.testLocalInitialBoolFlag.isRemotelyConfigured)
        XCTAssertFalse(FeatureFlag.testLocalInitialIntFlag.isRemotelyConfigured)
        XCTAssertFalse(FeatureFlag.testLocalInitialStringFlag.isRemotelyConfigured)
    }

    /// `name` formats the raw value of a feature flag
    func test_name() {
        XCTAssertEqual(FeatureFlag.testLocalFeatureFlag.name, "Test Local Feature Flag")
        XCTAssertEqual(FeatureFlag.testLocalInitialBoolFlag.name, "Test Local Initial Bool Flag")
        XCTAssertEqual(FeatureFlag.testLocalInitialIntFlag.name, "Test Local Initial Int Flag")
        XCTAssertEqual(FeatureFlag.testLocalInitialStringFlag.name, "Test Local Initial String Flag")
    }
}
