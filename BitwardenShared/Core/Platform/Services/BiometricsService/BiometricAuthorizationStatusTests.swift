import XCTest

@testable import BitwardenShared

final class BiometricAuthorizationStatusTests: BitwardenTestCase {
    // MARK: Tests

    func test_biometricAuthenticationType() {
        XCTAssertEqual(
            BiometricAuthenticationType.faceID,
            BiometricAuthorizationStatus.authorized(.faceID).biometricAuthenticationType
        )
        XCTAssertEqual(
            BiometricAuthenticationType.faceID,
            BiometricAuthorizationStatus.denied(.faceID).biometricAuthenticationType
        )
        XCTAssertEqual(
            BiometricAuthenticationType.faceID,
            BiometricAuthorizationStatus.lockedOut(.faceID).biometricAuthenticationType
        )
        XCTAssertEqual(
            BiometricAuthenticationType.faceID,
            BiometricAuthorizationStatus.notEnrolled(.faceID).biometricAuthenticationType
        )
        XCTAssertEqual(
            BiometricAuthenticationType.faceID,
            BiometricAuthorizationStatus.unknownError("", .faceID).biometricAuthenticationType
        )

        XCTAssertEqual(
            BiometricAuthenticationType.touchID,
            BiometricAuthorizationStatus.authorized(.touchID).biometricAuthenticationType
        )
        XCTAssertEqual(
            BiometricAuthenticationType.touchID,
            BiometricAuthorizationStatus.denied(.touchID).biometricAuthenticationType
        )
        XCTAssertEqual(
            BiometricAuthenticationType.touchID,
            BiometricAuthorizationStatus.lockedOut(.touchID).biometricAuthenticationType
        )
        XCTAssertEqual(
            BiometricAuthenticationType.touchID,
            BiometricAuthorizationStatus.notEnrolled(.touchID).biometricAuthenticationType
        )
        XCTAssertEqual(
            BiometricAuthenticationType.touchID,
            BiometricAuthorizationStatus.unknownError("", .touchID).biometricAuthenticationType
        )

        XCTAssertNil(
            BiometricAuthorizationStatus.noBiometrics.biometricAuthenticationType
        )
        XCTAssertNil(
            BiometricAuthorizationStatus.notDetermined.biometricAuthenticationType
        )
    }

    func test_shouldDisplayiometricsToggle() {
        XCTAssertTrue(BiometricAuthorizationStatus.authorized(.faceID).shouldDisplayiometricsToggle)
        XCTAssertFalse(BiometricAuthorizationStatus.denied(.faceID).shouldDisplayiometricsToggle)
        XCTAssertTrue(BiometricAuthorizationStatus.lockedOut(.faceID).shouldDisplayiometricsToggle)
        XCTAssertFalse(BiometricAuthorizationStatus.notEnrolled(.faceID).shouldDisplayiometricsToggle)
        XCTAssertFalse(
            BiometricAuthorizationStatus.unknownError("", .faceID).shouldDisplayiometricsToggle
        )

        XCTAssertTrue(BiometricAuthorizationStatus.authorized(.touchID).shouldDisplayiometricsToggle)
        XCTAssertFalse(BiometricAuthorizationStatus.denied(.touchID).shouldDisplayiometricsToggle)
        XCTAssertTrue(BiometricAuthorizationStatus.lockedOut(.touchID).shouldDisplayiometricsToggle)
        XCTAssertFalse(BiometricAuthorizationStatus.notEnrolled(.touchID).shouldDisplayiometricsToggle)
        XCTAssertFalse(
            BiometricAuthorizationStatus.unknownError("", .touchID).shouldDisplayiometricsToggle
        )

        XCTAssertFalse(BiometricAuthorizationStatus.noBiometrics.shouldDisplayiometricsToggle)
        XCTAssertFalse(BiometricAuthorizationStatus.notDetermined.shouldDisplayiometricsToggle)
    }
}
