import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

struct TOTPExpirationCalculatorTests {
    // MARK: Tests

    /// `hasCodeExpired` returns `true` when the code's generation date is in the distant past.
    @Test
    func hasCodeExpired_codesOlderThanPeriod() {
        let code = TOTPCodeModel(code: "", codeGenerationDate: .distantPast, period: 30)
        let timeProvider = MockTimeProvider(.currentTime)

        #expect(TOTPExpirationCalculator.hasCodeExpired(code, timeProvider: timeProvider))
    }

    /// `hasCodeExpired` returns `true` when the current time is past the code's expiration window.
    @Test
    func hasCodeExpired_recentCodesPastExpiration() {
        let code = TOTPCodeModel(
            code: "",
            codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 29),
            period: 30,
        )

        let expiredByOneSecond = MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1, second: 30)))
        #expect(TOTPExpirationCalculator.hasCodeExpired(code, timeProvider: expiredByOneSecond))

        let expiredByTwoSeconds = MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1, second: 31)))
        #expect(TOTPExpirationCalculator.hasCodeExpired(code, timeProvider: expiredByTwoSeconds))
    }

    /// `hasCodeExpired` returns `false` when the current time is still within the code's validity window.
    @Test
    func hasCodeExpired_currentCodes() {
        let codeGeneratedMidPeriod = TOTPCodeModel(
            code: "",
            codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 15),
            period: 30,
        )
        let atGenerationTime = MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1, second: 15)))
        #expect(!TOTPExpirationCalculator.hasCodeExpired(codeGeneratedMidPeriod, timeProvider: atGenerationTime))

        let codeGeneratedAtPeriodStart = TOTPCodeModel(
            code: "",
            codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 0),
            period: 30,
        )
        let nearEndOfWindow = MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1, second: 29)))
        #expect(!TOTPExpirationCalculator.hasCodeExpired(codeGeneratedAtPeriodStart, timeProvider: nearEndOfWindow))
    }

    /// `remainingSeconds` rounds up fractional seconds so that a code with any time remaining
    /// displays at least 1 second rather than 0.
    @Test
    func remainingSeconds_roundsUp() {
        let date = Date(year: 2024, month: 1, day: 1, second: 29, nanosecond: 90_000_000)
        let remaining = TOTPExpirationCalculator.remainingSeconds(for: date, using: 30)

        #expect(remaining == 1)
    }
}
