import BitwardenKit
import XCTest

@testable import AuthenticatorShared

final class FeatureFlagTests: BitwardenTestCase {
    // MARK: Tests

    /// `isRemotelyConfigured` returns the correct value for each flag.
    func test_isRemotelyConfigured() {
        XCTAssertTrue(FeatureFlag.enablePasswordManagerSync.isRemotelyConfigured)
    }
}
