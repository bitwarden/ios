import BitwardenKit

// MARK: - BankAccountType

/// The type of a bank account cipher, as serialized by the server.
public enum BankAccountType: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
    /// A checking account.
    case checking

    /// A savings account.
    case savings

    /// A certificate of deposit account.
    case certificateOfDeposit

    /// A line of credit account.
    case lineOfCredit

    /// An investment or brokerage account.
    case investmentBrokerage

    /// A money market account.
    case moneyMarket

    /// Any other account type not covered by the above.
    case other
}
