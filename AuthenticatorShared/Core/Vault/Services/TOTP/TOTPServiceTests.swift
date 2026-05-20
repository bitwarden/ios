import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

@testable import AuthenticatorShared

// MARK: - TOTPServiceTests

struct TOTPServiceTests {
    // MARK: Properties

    let clientService: MockClientService
    let errorReporter: MockErrorReporter
    let timeProvider: MockTimeProvider
    let subject: DefaultTOTPService

    // MARK: Initialization

    init() {
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        timeProvider = MockTimeProvider(.currentTime)

        subject = DefaultTOTPService(
            clientService: clientService,
            errorReporter: errorReporter,
            timeProvider: timeProvider,
        )
    }

    // MARK: Tests

    /// `getNextTOTPCode(for:)` generates a code dated one period in the future from the current time.
    @Test
    func getNextTOTPCode_usesNextPeriodDate() async throws {
        let fixedTime = Date(timeIntervalSinceReferenceDate: 1_000_000)
        timeProvider.timeConfig = .mockTime(fixedTime)
        let key = try subject.getTOTPConfiguration(key: .base32Key)

        let result = try await subject.getNextTOTPCode(for: key)

        let expectedDate = fixedTime.addingTimeInterval(Double(key.period))
        #expect(result.codeGenerationDate == expectedDate)
    }

    /// `getTOTPConfiguration(key:)` parses a base32-encoded key into a standard 6-digit, 30-second config.
    @Test
    func getTOTPConfiguration_base32_succeeds() throws {
        let config = try subject.getTOTPConfiguration(key: .base32Key)
        #expect(config.rawAuthenticatorKey == .base32Key)
        #expect(config.digits == 6)
        #expect(config.period == 30)
    }

    /// `getTOTPConfiguration(key:)` parses an OTP auth URI, extracting issuer, algorithm, digits, and period.
    @Test
    func getTOTPConfiguration_otpAuthUri_succeeds() throws {
        let config = try subject.getTOTPConfiguration(key: .otpAuthUriKeyComplete)
        #expect(config.issuer == "Example")
        #expect(config.algorithm == .sha256)
        #expect(config.digits == 6)
        #expect(config.period == 30)
    }

    /// `getTOTPConfiguration(key:)` parses a Steam URI key into a 5-digit, 30-second config.
    @Test
    func getTOTPConfiguration_steamUri_succeeds() throws {
        let config = try subject.getTOTPConfiguration(key: .steamUriKey)
        #expect(config.digits == 5)
        #expect(config.period == 30)
    }

    /// `getTOTPConfiguration(key:)` throws `.invalidKeyFormat` for an unrecognized key string.
    @Test
    func getTOTPConfiguration_invalidKey_throwsInvalidKeyFormat() {
        #expect(throws: TOTPKeyError.invalidKeyFormat) {
            try subject.getTOTPConfiguration(key: "1234")
        }
    }
}
