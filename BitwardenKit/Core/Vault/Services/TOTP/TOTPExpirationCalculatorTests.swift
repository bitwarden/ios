import BitwardenKitMocks
import Foundation
import Testing

@testable import BitwardenKit

struct TOTPExpirationCalculatorTests {
    // MARK: Tests

    /// `hasCodeExpired` returns `true` when the code's generation date is in the distant past.
    @Test
    func hasCodeExpired_codesOlderThanPeriod() {
        #expect(
            TOTPExpirationCalculator.hasCodeExpired(
                TOTPCodeModel(
                    code: "",
                    codeGenerationDate: .distantPast,
                    period: 30,
                ),
                timeProvider: MockTimeProvider(.currentTime),
            )
        )
    }

    /// `hasCodeExpired` returns `true` when the current time is past the code's expiration window.
    @Test
    func hasCodeExpired_recentCodesPastExpiration() {
        #expect(
            TOTPExpirationCalculator.hasCodeExpired(
                TOTPCodeModel(
                    code: "",
                    codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 29),
                    period: 30,
                ),
                timeProvider: MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1, second: 30))),
            )
        )
        #expect(
            TOTPExpirationCalculator.hasCodeExpired(
                TOTPCodeModel(
                    code: "",
                    codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 29),
                    period: 30,
                ),
                timeProvider: MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1, second: 31))),
            )
        )
    }

    /// `hasCodeExpired` returns `false` when the current time is still within the code's validity window.
    @Test
    func hasCodeExpired_currentCodes() {
        #expect(
            !TOTPExpirationCalculator.hasCodeExpired(
                TOTPCodeModel(
                    code: "",
                    codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 15),
                    period: 30,
                ),
                timeProvider: MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1, second: 15))),
            )
        )
        #expect(
            !TOTPExpirationCalculator.hasCodeExpired(
                TOTPCodeModel(
                    code: "",
                    codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 0),
                    period: 30,
                ),
                timeProvider: MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1, second: 29))),
            )
        )
    }

    /// `remainingSeconds` rounds up fractional seconds so that a code with any time remaining
    /// displays at least 1 second rather than 0.
    @Test
    func remainingSeconds_roundsUp() {
        #expect(
            TOTPExpirationCalculator.remainingSeconds(
                for: Date(year: 2024, month: 1, day: 1, second: 29, nanosecond: 90_000_000),
                using: 30,
            ) == 1
        )
    }
}
