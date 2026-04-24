import AuthenticatorSharedMocks
import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import AuthenticatorShared

final class TOTPExpirationCalculatorTests: BitwardenTestCase {
    // MARK: Tests

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
}
