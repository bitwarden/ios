import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

final class TOTPExpirationCalculatorTests: BitwardenTestCase {
    // MARK: Tests

    func test_listItemsByExpiration() {
        let expired = VaultListItem.fixtureTOTP(
            totp: .fixture(
                totpCode: .init(
                    code: "",
                    codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 29),
                    period: 30,
                ),
            ),
        )
        let current = VaultListItem.fixtureTOTP(
            totp: .fixture(
                totpCode: .init(
                    code: "",
                    codeGenerationDate: Date(year: 2024, month: 1, day: 1, second: 31),
                    period: 30,
                ),
            ),
        )
        let expectation = [
            true: [
                expired,
            ],
            false: [
                current,
            ],
        ]
        XCTAssertEqual(
            expectation,
            TOTPExpirationCalculator.listItemsByExpiration(
                [current, expired],
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
