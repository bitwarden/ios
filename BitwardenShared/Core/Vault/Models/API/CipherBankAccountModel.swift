/// API model for a bank account cipher.
///
/// Every field defaults to `nil` so callers can use the synthesized memberwise init
/// conveniently and so the JSON payload minimizes absent fields.
///
/// - Important: Instances of this model are **never** to be serialized directly to a
///   request body reaching the server. All persisted bank account data must pass
///   through the `BitwardenSdk` encryption path (`CipherView.bankAccount` /
///   `Cipher.bankAccount` once the SDK exposes those types). This model is strictly an
///   intermediate representation for JSON round-tripping when the SDK is not yet
///   available (TODO: PM-32009 Blocked on SDK). See the serialization tripwire in
///   `BankAccountItemState.apiModel`.
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

    // MARK: Initialization

    /// Creates a new `CipherBankAccountModel`. All parameters default to `nil` so
    /// callers can build minimal payloads without listing every field.
    ///
    /// - Parameters:
    ///   - accountNumber: The account number (sensitive).
    ///   - accountType: The bank account type.
    ///   - bankName: The name of the bank.
    ///   - bankPhone: The bank contact phone number.
    ///   - branchNumber: The branch number of the bank.
    ///   - iban: The IBAN.
    ///   - nameOnAccount: The name on the account.
    ///   - pin: The personal identification number (sensitive).
    ///   - routingNumber: The routing number.
    ///   - swiftCode: The SWIFT / BIC code.
    ///
    init(
        accountNumber: String? = nil,
        accountType: BankAccountType? = nil,
        bankName: String? = nil,
        bankPhone: String? = nil,
        branchNumber: String? = nil,
        iban: String? = nil,
        nameOnAccount: String? = nil,
        pin: String? = nil,
        routingNumber: String? = nil,
        swiftCode: String? = nil,
    ) {
        self.accountNumber = accountNumber
        self.accountType = accountType
        self.bankName = bankName
        self.bankPhone = bankPhone
        self.branchNumber = branchNumber
        self.iban = iban
        self.nameOnAccount = nameOnAccount
        self.pin = pin
        self.routingNumber = routingNumber
        self.swiftCode = swiftCode
    }
}
