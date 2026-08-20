import BitwardenResources
import Foundation
import Testing

@testable import BitwardenShared

struct BankAccountTypeTests {
    // MARK: Tests

    /// `defaultValueLocalizedName` is the localized `None` placeholder shown when no account
    /// type is selected.
    @Test
    func defaultValueLocalizedName_isNone() {
        #expect(BankAccountType.defaultValueLocalizedName == Localizations.none)
    }

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

    /// `displayOrder` matches the order specified by design.
    @Test
    func displayOrder_matchesDesign() {
        #expect(BankAccountType.displayOrder == [
            .checking,
            .savings,
            .certificateOfDeposit,
            .lineOfCredit,
            .investmentBrokerage,
            .moneyMarket,
            .other,
        ])
    }

    /// `displayOrder` contains every case exactly once, so a newly added case can't be silently
    /// left out of the menu.
    @Test
    func displayOrder_containsAllCases() {
        #expect(Set(BankAccountType.displayOrder) == Set(BankAccountType.allCases))
        #expect(BankAccountType.displayOrder.count == BankAccountType.allCases.count)
    }
}
