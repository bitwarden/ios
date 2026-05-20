import Foundation
import Testing

@testable import BitwardenShared

struct BankAccountTypeTests {
    // MARK: Tests

    /// Raw values match the server contract.
    @Test
    func rawValues_matchServerContract() {
        #expect(BankAccountType.certificateOfDeposit.rawValue == "certificateOfDeposit")
        #expect(BankAccountType.checking.rawValue == "checking")
        #expect(BankAccountType.investmentBrokerage.rawValue == "investmentBrokerage")
        #expect(BankAccountType.lineOfCredit.rawValue == "lineOfCredit")
        #expect(BankAccountType.moneyMarket.rawValue == "moneyMarket")
        #expect(BankAccountType.other.rawValue == "other")
        #expect(BankAccountType.savings.rawValue == "savings")
    }
}
