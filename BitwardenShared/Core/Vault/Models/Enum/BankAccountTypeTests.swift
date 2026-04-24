import Foundation
import Testing

@testable import BitwardenShared

class BankAccountTypeTests {
    // MARK: Tests

    /// Raw values match the server contract.
    @Test
    func rawValues_matchServerContract() {
        #expect(BankAccountType.checking.rawValue == "checking")
        #expect(BankAccountType.savings.rawValue == "savings")
        #expect(BankAccountType.certificateOfDeposit.rawValue == "certificateOfDeposit")
        #expect(BankAccountType.lineOfCredit.rawValue == "lineOfCredit")
        #expect(BankAccountType.investmentBrokerage.rawValue == "investmentBrokerage")
        #expect(BankAccountType.moneyMarket.rawValue == "moneyMarket")
        #expect(BankAccountType.other.rawValue == "other")
    }

    /// `allCases` exposes every account type in declaration order.
    @Test
    func allCases_declarationOrder() {
        #expect(
            BankAccountType.allCases == [
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

    /// Each case round-trips through JSON as its raw string value.
    @Test
    func codable_roundTrip() throws {
        for bankAccountType in BankAccountType.allCases {
            let encoded = try JSONEncoder().encode(bankAccountType)
            let decoded = try JSONDecoder().decode(BankAccountType.self, from: encoded)
            #expect(decoded == bankAccountType)
            #expect(String(data: encoded, encoding: .utf8) == "\"\(bankAccountType.rawValue)\"")
        }
    }
}
