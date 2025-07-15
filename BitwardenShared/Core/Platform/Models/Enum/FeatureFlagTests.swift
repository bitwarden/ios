import BitwardenKit
import XCTest

@testable import BitwardenShared

final class FeatureFlagTests: BitwardenTestCase {
    // MARK: Tests

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
        XCTAssertTrue(FeatureFlag.restrictCipherItemDeletion.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.simpleLoginSelfHostAlias.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.mobileErrorReporting.isRemotelyConfigured)
        XCTAssertTrue(FeatureFlag.removeCardPolicy.isRemotelyConfigured)

        XCTAssertFalse(FeatureFlag.enableCipherKeyEncryption.isRemotelyConfigured)
        XCTAssertFalse(FeatureFlag.ignore2FANoticeEnvironmentCheck.isRemotelyConfigured)
    }
}
