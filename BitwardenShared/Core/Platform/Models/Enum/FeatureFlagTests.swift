import BitwardenKit
import XCTest

@testable import BitwardenShared

final class FeatureFlagTests: BitwardenTestCase {
    // MARK: Tests

    /// `initialValues` returns the correct value for each flag.
    func test_initialValues() {
        XCTAssertNil(FeatureFlag.cardScanner.initialValue?.boolValue)
        XCTAssertNil(FeatureFlag.policiesInAcceptedState.initialValue?.boolValue)
    }
}
