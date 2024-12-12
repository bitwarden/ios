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

    /// `getter:isRemotelyConfigured` returns the correct value for each flag.
    func test_isRemotelyConfigured() {
        XCTAssertTrue(FeatureFlag.cxpExportMobile.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.cxpImportMobile.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.emailVerification.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.enableAuthenticatorSync.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.refactorSsoDetailsEndpoint.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.sshKeyVaultItem.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.testRemoteInitialBoolFlag.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.testRemoteInitialIntFlag.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.testRemoteInitialStringFlag.isRemotelyConfigured)

        XCTAssertFalse(FeatureFlag.enableCipherKeyEncryption.isRemotelyConfigured)
        XCTAssertFalse(FeatureFlag.importLoginsFlow.isRemotelyConfigured)
        XCTAssertFalse(FeatureFlag.nativeCarouselFlow.isRemotelyConfigured)
        XCTAssertFalse(FeatureFlag.nativeCreateAccountFlow.isRemotelyConfigured)
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
