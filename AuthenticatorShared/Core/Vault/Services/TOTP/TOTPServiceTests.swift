import XCTest

@testable import AuthenticatorShared

// MARK: - TOTPServiceTests

final class TOTPServiceTests: AuthenticatorTestCase {
    // MARK: Properties

    var clientVaultService: MockClientVaultService!
    var errorReporter: MockErrorReporter!
    var timeProvider: MockTimeProvider!
    var subject: DefaultTOTPService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientVaultService = MockClientVaultService()
        errorReporter = MockErrorReporter()
        timeProvider = MockTimeProvider(.currentTime)

        subject = DefaultTOTPService(
            clientVault: clientVaultService,
            errorReporter: errorReporter,
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        clientVaultService = nil
        errorReporter = nil
        timeProvider = nil
        subject = nil
    }

    // MARK: Tests

    func test_default_getTOTPConfiguration_base32() throws {
        let config = try subject
            .getTOTPConfiguration(key: .base32Key)
        XCTAssertNotNil(config)
    }

    func test_default_getTOTPConfiguration_otp() throws {
        let config = try subject
            .getTOTPConfiguration(key: .otpAuthUriKeyComplete)
        XCTAssertNotNil(config)
    }

    func test_default_getTOTPConfiguration_steam() throws {
        let config = try subject
            .getTOTPConfiguration(key: .steamUriKey)
        XCTAssertNotNil(config)
    }

    func test_default_getTOTPConfiguration_failure() {
        XCTAssertThrowsError(
            try subject.getTOTPConfiguration(key: "1234")
        ) { error in
            XCTAssertEqual(
                error as? TOTPServiceError,
                .invalidKeyFormat
            )
        }
    }
}
