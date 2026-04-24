import BitwardenKit
import BitwardenResources

// MARK: - BankAccountType

/// An enum describing the type of a bank account cipher.
///
public enum BankAccountType: Int, Codable, CaseIterable, Sendable {
    /// A checking account.
    case checking = 0

    /// A savings account.
    case savings = 1

    /// A certificate of deposit (CD) account.
    case certificateOfDeposit = 2

    /// A line of credit account.
    case lineOfCredit = 3

    /// An investment / brokerage account.
    case investmentBrokerage = 4

    /// A money market account.
    case moneyMarket = 5

    /// Any other type of bank account not covered by the explicit cases.
    case other = 6
}

extension BankAccountType: Menuable {
    public var localizedName: String {
        switch self {
        case .checking: Localizations.checking
        case .savings: Localizations.savings
        case .certificateOfDeposit: Localizations.certificateOfDeposit
        case .lineOfCredit: Localizations.lineOfCredit
        case .investmentBrokerage: Localizations.investmentBrokerage
        case .moneyMarket: Localizations.moneyMarket
        case .other: Localizations.other
        }
    }
}
