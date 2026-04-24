import BitwardenKitMocks
import Foundation
import Testing

@testable import BitwardenKit

struct TOTPExpirationCalculatorTests {
    // MARK: Tests

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
