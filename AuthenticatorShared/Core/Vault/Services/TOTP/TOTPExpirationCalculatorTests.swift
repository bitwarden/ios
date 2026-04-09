import AuthenticatorSharedMocks
import BitwardenKitMocks
import XCTest

@testable import AuthenticatorShared

final class TOTPExpirationCalculatorTests: BitwardenTestCase {
    // MARK: Tests

    func test_hasCodeExpired_codesOlderThanPeriod() {
        XCTAssertTrue(
            TOTPExpirationCalculator.hasCodeExpired(
                .init(
                    code: "",
                    codeGenerationDate: .distantPast,
                    period: 30,
                ),
                timeProvider: MockTimeProvider(.currentTime),
            ),
        )
    }

    func test_hasCodeExpired_recentCodesPastExpiration() {
        XCTAssertTrue(
            TOTPExpirationCalculator.hasCodeExpired(
                .init(
                    code: "",
                    codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 29),
                    period: 30,
                ),
                timeProvider: MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1, second: 30))),
            ),
        )
        XCTAssertTrue(
            TOTPExpirationCalculator.hasCodeExpired(
                .init(
                    code: "",
                    codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 29),
                    period: 30,
                ),
                timeProvider: MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1, second: 31))),
            ),
        )
    }

    func test_hasCodeExpired_currentCodes() {
        XCTAssertFalse(
            TOTPExpirationCalculator.hasCodeExpired(
                .init(
                    code: "",
                    codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 15),
                    period: 30,
                ),
                timeProvider: MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1, second: 15))),
            ),
        )
        XCTAssertFalse(
            TOTPExpirationCalculator.hasCodeExpired(
                .init(
                    code: "",
                    codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 0),
                    period: 30,
                ),
                timeProvider: MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1, second: 29))),
            ),
        )
    }

    func test_listItemsByExpiration() {
        let expiredTotp = TOTPCodeModel(
            code: "",
            codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 29),
            period: 30,
        )
        let expired = ItemListItem.fixture(totp: ItemListTotpItem.fixture(totpCode: expiredTotp))
        let expiredShared = ItemListItem.fixtureShared(
            totp: ItemListSharedTotpItem.fixture(totpCode: expiredTotp),
        )
        let currentTotp = TOTPCodeModel(
            code: "",
            codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 31),
            period: 30,
        )
        let current = ItemListItem.fixture(totp: ItemListTotpItem.fixture(totpCode: currentTotp))
        let currentShared = ItemListItem.fixtureShared(
            totp: ItemListSharedTotpItem.fixture(totpCode: currentTotp),
        )
        let expectation = [
            true: [
                expired,
                expiredShared,
            ],
            false: [
                current,
                currentShared,
            ],
        ]
        XCTAssertEqual(
            expectation,
            TOTPExpirationCalculator.listItemsByExpiration(
                [current, currentShared, expired, expiredShared],
                timeProvider: MockTimeProvider(
                    .mockTime(
                        Date(
                            year: 2024,
                            month: 1,
                            day: 1,
                            second: 31,
                        ),
                    ),
                ),
            ),
        )
    }

    func test_remainingSeconds_roundsUp() {
        XCTAssertEqual(
            TOTPExpirationCalculator.remainingSeconds(
                for: Date(year: 2024, month: 1, day: 1, second: 29, nanosecond: 90_000_000),
                using: 30,
            ),
            1,
        )
    }
}
