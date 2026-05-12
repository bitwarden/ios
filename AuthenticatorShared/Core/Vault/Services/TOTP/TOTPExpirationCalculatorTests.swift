import AuthenticatorSharedMocks
import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

@testable import AuthenticatorShared

struct TOTPExpirationCalculatorTests {
    // MARK: Tests

    /// `listItemsByExpiration` correctly partitions items into expired and current groups.
    @Test
    func listItemsByExpiration() {
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
        #expect(
            expectation == TOTPExpirationCalculator.listItemsByExpiration(
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
