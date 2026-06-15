import BitwardenKit
import BitwardenSdk

// MARK: - BankAccountItemState

/// A model for a bank account item.
///
struct BankAccountItemState: Equatable {
    /// The account number of the bank account.
    var accountNumber: String = ""

    /// The type of the bank account.
    var accountType: DefaultableType<BankAccountType> = .default

    /// The contact phone number for the bank.
    var bankContactPhone: String = ""

    /// The name of the bank.
    var bankName: String = ""

    /// The branch number of the bank account.
    var branchNumber: String = ""

    /// The international bank account number (IBAN).
    var iban: String = ""

    /// The visibility of the account number.
    var isAccountNumberVisible: Bool = false

    /// The visibility of the IBAN.
    var isIbanVisible: Bool = false

    /// The visibility of the PIN.
    var isPinVisible: Bool = false

    /// The name on the bank account.
    var nameOnAccount: String = ""

    /// The PIN of the bank account.
    var pin: String = ""

    /// The routing number of the bank account.
    var routingNumber: String = ""

    /// The SWIFT/BIC code of the bank.
    var swiftCode: String = ""
}

extension BankAccountItemState {
    /// The `BankAccountView` representation of the state, used to round-trip through the SDK.
    var bankAccountView: BankAccountView {
        .init(
            bankName: bankName.nilIfEmpty,
            nameOnAccount: nameOnAccount.nilIfEmpty,
            accountType: {
                guard case let .custom(type) = accountType else { return nil }
                return type.rawValue
            }(),
            accountNumber: accountNumber.nilIfEmpty,
            routingNumber: routingNumber.nilIfEmpty,
            branchNumber: branchNumber.nilIfEmpty,
            pin: pin.nilIfEmpty,
            swiftCode: swiftCode.nilIfEmpty,
            iban: iban.nilIfEmpty,
            bankContactPhone: bankContactPhone.nilIfEmpty,
        )
    }
}

// MARK: AddEditBankAccountItemState

extension BankAccountItemState: AddEditBankAccountItemState {}
