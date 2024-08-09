import XCTest

@testable import BitwardenShared

// MARK: - TOTPServiceTests

final class TOTPServiceTests: BitwardenTestCase {
    // MARK: Tests

    func test_default_getTOTPConfiguration_base32() throws {
        let config = try DefaultTOTPService()
            .getTOTPConfiguration(key: .base32Key)
        XCTAssertNotNil(config)
    }

    func test_default_getTOTPConfiguration_otp() throws {
        let config = try DefaultTOTPService()
            .getTOTPConfiguration(key: .otpAuthUriKeyComplete)
        XCTAssertNotNil(config)
    }

    func test_default_getTOTPConfiguration_steam() throws {
        let config = try DefaultTOTPService()
            .getTOTPConfiguration(key: .steamUriKey)
        XCTAssertNotNil(config)
    }

    func test_default_getTOTPConfiguration_failure() {
        XCTAssertThrowsError(
            try DefaultTOTPService().getTOTPConfiguration(key: "1234")
        ) { error in
            XCTAssertEqual(
                error as? TOTPServiceError,
                .invalidKeyFormat
            )
        }
    }
}
