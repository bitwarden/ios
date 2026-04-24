/// API model for a bank account cipher.
///
struct CipherBankAccountModel: Codable, Equatable, Sendable {
    // MARK: Properties

    /// The account number (sensitive; rendered as a hidden field in the UI).
    let accountNumber: String?

    /// The type of the bank account (e.g., checking, savings).
    let accountType: BankAccountType?

    /// The name of the bank.
    let bankName: String?

    /// The phone number for contacting the bank.
    let bankPhone: String?

    /// The branch number of the bank.
    let branchNumber: String?

    /// The IBAN (International Bank Account Number).
    let iban: String?

    /// The name on the account.
    let nameOnAccount: String?

    /// The personal identification number (sensitive; rendered as a hidden field in the UI).
    let pin: String?

    /// The routing number of the bank.
    let routingNumber: String?

    /// The SWIFT / BIC code of the bank.
    let swiftCode: String?
}
