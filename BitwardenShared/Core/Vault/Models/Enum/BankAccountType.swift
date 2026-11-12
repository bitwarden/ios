import BitwardenKit

// MARK: - BankAccountType

/// The type of a bank account cipher, as serialized by the server.
public enum BankAccountType: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    /// A certificate of deposit account.
    case certificateOfDeposit

    /// A checking account.
    case checking

    /// An investment or brokerage account.
    case investmentBrokerage

    /// A line of credit account.
    case lineOfCredit

    /// A money market account.
    case moneyMarket

    /// Any account type not covered by the other options.
    case other

    /// A savings account.
    case savings

    /// The cases in the order they should be displayed to the user, per design.
    public static let displayOrder: [BankAccountType] = [
        .checking,
        .savings,
        .certificateOfDeposit,
        .lineOfCredit,
        .investmentBrokerage,
        .moneyMarket,
        .other,
    ]
}
