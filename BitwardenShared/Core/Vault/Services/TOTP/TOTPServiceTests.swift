import XCTest

@testable import BitwardenShared

// MARK: - TOTPServiceTests

final class TOTPServiceTests: BitwardenTestCase {
    // MARK: Tests

    func test_default_getTOTPConfiguration_base32() throws {
        let config = try DefaultTOTPService().getTOTPConfiguration(key: .base32Key)
        XCTAssertEqual(config.totpKey, .base32(key: .base32Key))
    }

    func test_default_getTOTPConfiguration_otp() throws {
        let config = try DefaultTOTPService().getTOTPConfiguration(key: .otpAuthUriKeyComplete)
        XCTAssertEqual(config.totpKey, .otpAuthUri(.init(otpAuthKey: .otpAuthUriKeyComplete)!))
    }

    func test_default_getTOTPConfiguration_steam() throws {
        let config = try DefaultTOTPService().getTOTPConfiguration(key: .steamUriKey)
        XCTAssertEqual(config.totpKey, .steamUri(key: .steamUriKeyIdentifier))
    }

    func test_default_getTOTPConfiguration_unknown() throws {
        let keyWithSpaces = "key with spaces"
        let config = try DefaultTOTPService().getTOTPConfiguration(key: keyWithSpaces)
        XCTAssertEqual(config.totpKey, .unknown(key: keyWithSpaces))
    }

    func test_default_getTOTPConfiguration_failure() {
        XCTAssertThrowsError(try DefaultTOTPService().getTOTPConfiguration(key: nil)) { error in
            XCTAssertEqual(error as? TOTPServiceError, .invalidKeyFormat)
        }
    }
}
