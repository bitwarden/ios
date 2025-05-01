import BitwardenKit
import XCTest

@testable import BitwardenShared

extension FeatureFlag {
    static let testLocalFeatureFlag = FeatureFlag(
        rawValue: "test-local-feature-flag",
        isRemotelyConfigured: false
    )

    static let testLocalInitialBoolFlag = FeatureFlag(
        rawValue: "test-local-initial-bool-flag",
        initialValue: .bool(true),
        isRemotelyConfigured: false
    )

    static let testLocalInitialIntFlag = FeatureFlag(
        rawValue: "test-local-initial-int-flag",
        initialValue: .int(42),
        isRemotelyConfigured: false
    )

    static let testLocalInitialStringFlag = FeatureFlag(
        rawValue: "test-local-initial-string-flag",
        initialValue: .string("Test String"),
        isRemotelyConfigured: false
    )

    static let testRemoteFeatureFlag = FeatureFlag(
        rawValue: "test-remote-feature-flag",
        isRemotelyConfigured: true
    )

    static let testRemoteInitialBoolFlag = FeatureFlag(
        rawValue: "test-remote-initial-bool-flag",
        initialValue: .bool(true),
        isRemotelyConfigured: true
    )

    static let testRemoteInitialIntFlag = FeatureFlag(
        rawValue: "test-remote-initial-int-flag",
        initialValue: .int(42),
        isRemotelyConfigured: true
    )

    static let testRemoteInitialStringFlag = FeatureFlag(
        rawValue: "test-remote-initial-string-flag",
        initialValue: .string("Test String"),
        isRemotelyConfigured: true
    )

    //
    //    /// A test feature flag that has an initial integer value and is not remotely configured.
    //    case testLocalInitialIntFlag = "test-local-initial-int-flag"
    //
    //    /// A test feature flag that has an initial string value and is not remotely configured.
    //    case testLocalInitialStringFlag = "test-local-initial-string-flag"
    //
    //    /// A test feature flag that can be remotely configured.
    //    case testRemoteFeatureFlag = "test-remote-feature-flag"
    //
    //    /// A test feature flag that has an initial boolean value and is not remotely configured.
    //    case testRemoteInitialBoolFlag = "test-remote-initial-bool-flag"
    //
    //    /// A test feature flag that has an initial integer value and is not remotely configured.
    //    case testRemoteInitialIntFlag = "test-remote-initial-int-flag"
    //
    //    /// A test feature flag that has an initial string value and is not remotely configured.
    //    case testRemoteInitialStringFlag = "test-remote-initial-string-flag"

}

final class FeatureFlagTests: BitwardenTestCase {
    // MARK: Tests

    /// `debugMenuFeatureFlags` does not include any test flags
//    func test_debugMenu_testFlags() {
//        let actual = FeatureFlag.debugMenuFeatureFlags.map(\.rawValue)
//        let filtered = actual.filter { $0.hasPrefix("test-") }
//        XCTAssertEqual(filtered, [])
//    }

    /// `initialValues` returns the correct value for each flag.
    func test_initialValues() {
        XCTAssertNil(FeatureFlag.cipherKeyEncryption.initialValue?.boolValue)
    }

    /// `getter:isRemotelyConfigured` returns the correct value for each flag.
    func test_isRemotelyConfigured() {
        XCTAssertTrue(FeatureFlag.anonAddySelfHostAlias.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.cipherKeyEncryption.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.cxpExportMobile.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.cxpImportMobile.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.emailVerification.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.enableAuthenticatorSync.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.importLoginsFlow.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.nativeCreateAccountFlow.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.refactorSsoDetailsEndpoint.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.restrictCipherItemDeletion.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.simpleLoginSelfHostAlias.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.testRemoteInitialBoolFlag.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.testRemoteInitialIntFlag.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.testRemoteInitialStringFlag.isRemotelyConfigured)

        XCTAssertFalse(FeatureFlag.enableCipherKeyEncryption.isRemotelyConfigured)
        XCTAssertFalse(FeatureFlag.flightRecorder.isRemotelyConfigured)
        XCTAssertFalse(FeatureFlag.ignore2FANoticeEnvironmentCheck.isRemotelyConfigured)
        XCTAssertFalse(FeatureFlag.mobileErrorReporting.isRemotelyConfigured)
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
