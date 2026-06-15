import BitwardenKit
import BitwardenResources

// MARK: - AddEditBankAccountItemState

/// A protocol for a sendable type that models a bank account item in its add/edit state.
///
protocol AddEditBankAccountItemState: Equatable, Sendable {
    /// The account number of the bank account.
    var accountNumber: String { get set }

    /// The type of the bank account.
    var accountType: DefaultableType<BankAccountType> { get set }

    /// The contact phone number for the bank.
    var bankContactPhone: String { get set }

    /// The name of the bank.
    var bankName: String { get set }

    /// The branch number of the bank account.
    var branchNumber: String { get set }

    /// The international bank account number (IBAN).
    var iban: String { get set }

    /// The visibility of the account number.
    var isAccountNumberVisible: Bool { get set }

    /// The visibility of the IBAN.
    var isIbanVisible: Bool { get set }

    /// The visibility of the PIN.
    var isPinVisible: Bool { get set }

    /// The name on the bank account.
    var nameOnAccount: String { get set }

    /// The PIN of the bank account.
    var pin: String { get set }

    /// The routing number of the bank account.
    var routingNumber: String { get set }

    /// The SWIFT/BIC code of the bank.
    var swiftCode: String { get set }
}

// MARK: - BankAccountType + Menuable

extension BankAccountType: Menuable {
    /// The default placeholder shown when no account type is selected.
    public static var defaultValueLocalizedName: String {
        "--\(Localizations.select)--"
    }

    /// A localized string representation of the account type.
    public var localizedName: String {
        switch self {
        case .certificateOfDeposit:
            Localizations.certificateOfDeposit
        case .checking:
            Localizations.checking
        case .investmentBrokerage:
            Localizations.investmentBrokerage
        case .lineOfCredit:
            Localizations.lineOfCredit
        case .moneyMarket:
            Localizations.moneyMarket
        case .other:
            Localizations.other
        case .savings:
            Localizations.savings
        }
    }
}
