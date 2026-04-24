// MARK: - ViewBankAccountItemState

/// A protocol for an equatable type that models a Bank Account Item in its view state.
///
protocol ViewBankAccountItemState: Equatable, Sendable {
    /// The account number.
    var accountNumber: String { get }

    /// The type of the bank account.
    var accountType: DefaultableType<BankAccountType> { get }

    /// The name of the bank.
    var bankName: String { get }

    /// The phone number for contacting the bank.
    var bankPhone: String { get }

    /// The branch number of the bank.
    var branchNumber: String { get }

    /// The IBAN.
    var iban: String { get }

    /// Whether the account number is visible.
    var isAccountNumberVisible: Bool { get }

    /// Whether the bank account details section has no user-populated content.
    var isBankAccountDetailsSectionEmpty: Bool { get }

    /// Whether the PIN is visible.
    var isPinVisible: Bool { get }

    /// The name on the account.
    var nameOnAccount: String { get }

    /// The personal identification number.
    var pin: String { get }

    /// The routing number of the bank.
    var routingNumber: String { get }

    /// The SWIFT / BIC code of the bank.
    var swiftCode: String { get }
}
