import BitwardenResources
import XCTest

@testable import BitwardenShared

class BankAccountTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// Each case has a distinct raw value matching the cross-platform contract.
    func test_rawValues_matchContract() {
        XCTAssertEqual(BankAccountType.checking.rawValue, 0)
        XCTAssertEqual(BankAccountType.savings.rawValue, 1)
        XCTAssertEqual(BankAccountType.certificateOfDeposit.rawValue, 2)
        XCTAssertEqual(BankAccountType.lineOfCredit.rawValue, 3)
        XCTAssertEqual(BankAccountType.investmentBrokerage.rawValue, 4)
        XCTAssertEqual(BankAccountType.moneyMarket.rawValue, 5)
        XCTAssertEqual(BankAccountType.other.rawValue, 6)
    }

    /// `allCases` exposes all seven account types in stable order.
    func test_allCases_ordering() {
        XCTAssertEqual(
            BankAccountType.allCases,
            [
                .checking,
                .savings,
                .certificateOfDeposit,
                .lineOfCredit,
                .investmentBrokerage,
                .moneyMarket,
                .other,
            ],
        )
    }

    /// Each case has a non-empty localized name.
    func test_localizedName_isNotEmpty() {
        for bankAccountType in BankAccountType.allCases {
            XCTAssertFalse(bankAccountType.localizedName.isEmpty, "Missing localizedName for \(bankAccountType)")
        }
    }

    /// Raw values round-trip through JSON encoding.
    func test_codable_roundTrip() throws {
        for bankAccountType in BankAccountType.allCases {
            let encoded = try JSONEncoder().encode(bankAccountType)
            let decoded = try JSONDecoder().decode(BankAccountType.self, from: encoded)
            XCTAssertEqual(decoded, bankAccountType)
        }
    }
}
