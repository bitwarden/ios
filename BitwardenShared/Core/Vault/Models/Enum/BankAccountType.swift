import BitwardenKit
import BitwardenResources

// MARK: - BankAccountType

/// An enum describing the type of a bank account cipher.
///
/// - Note: `Menuable` conformance (and the seven localized display-name keys it
///   depends on) is deferred to PM-32809 Part 3/3, where the add/edit UI introduces
///   the `BitwardenMenuField` that consumes it. Part 1/3 ships only the raw enum so
///   `CipherBankAccountModel` can store/decode the value without pulling UI-facing
///   localization keys into this slice.
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
