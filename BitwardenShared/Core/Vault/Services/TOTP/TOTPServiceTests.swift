import XCTest

@testable import BitwardenShared

// MARK: - TOTPServiceTests

final class TOTPServiceTests: BitwardenTestCase {
    // MARK: Tests

    func test_default_getTOTPConfiguration_base32() throws {
        let config = DefaultTOTPService().getTOTPConfiguration(key: .standardTotpKey)
        XCTAssertEqual(config.totpKey, .standard(key: .standardTotpKey))
    }

    func test_default_getTOTPConfiguration_otp() throws {
        let config = DefaultTOTPService().getTOTPConfiguration(key: .otpAuthUriKeyComplete)
        XCTAssertEqual(config.totpKey, .otpAuthUri(.init(otpAuthKey: .otpAuthUriKeyComplete)!))
    }

    func test_default_getTOTPConfiguration_steam() throws {
        let config = DefaultTOTPService().getTOTPConfiguration(key: .steamUriKey)
        XCTAssertEqual(config.totpKey, .steamUri(key: .steamUriKeyIdentifier))
    }

    func test_default_getTOTPConfiguration_standard() throws {
        let keyWithSpaces = "key with spaces"
        let config = DefaultTOTPService().getTOTPConfiguration(key: keyWithSpaces)
        XCTAssertEqual(config.totpKey, .standard(key: keyWithSpaces))
    }
}
