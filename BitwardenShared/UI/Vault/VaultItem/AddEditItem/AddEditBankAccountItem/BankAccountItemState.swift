import BitwardenSdk
import Foundation

// MARK: - BankAccountItemState

/// A model for a bank account item.
///
struct BankAccountItemState: Equatable, Sendable {
    // MARK: Properties

    /// The account number.
    var accountNumber: String = ""

    /// The type of the bank account.
    var accountType: DefaultableType<BankAccountType> = .default

    /// The name of the bank.
    var bankName: String = ""

    /// The phone number for contacting the bank.
    var bankPhone: String = ""

    /// The branch number of the bank.
    var branchNumber: String = ""

    /// The IBAN (International Bank Account Number).
    var iban: String = ""

    /// The visibility of the account number field.
    var isAccountNumberVisible: Bool = false

    /// The visibility of the PIN field.
    var isPinVisible: Bool = false

    /// The name on the account.
    var nameOnAccount: String = ""

    /// The personal identification number.
    var pin: String = ""

    /// The routing number of the bank.
    var routingNumber: String = ""

    /// The SWIFT / BIC code of the bank.
    var swiftCode: String = ""
}

// MARK: - API Round-trip helpers

extension BankAccountItemState {
    /// Builds an API `CipherBankAccountModel` representation of this state.
    ///
    /// Empty text fields are serialized as `nil`.
    ///
    var apiModel: CipherBankAccountModel {
        CipherBankAccountModel(
            accountNumber: accountNumber.nilIfEmpty,
            accountType: accountType.customValue,
            bankName: bankName.nilIfEmpty,
            bankPhone: bankPhone.nilIfEmpty,
            branchNumber: branchNumber.nilIfEmpty,
            iban: iban.nilIfEmpty,
            nameOnAccount: nameOnAccount.nilIfEmpty,
            pin: pin.nilIfEmpty,
            routingNumber: routingNumber.nilIfEmpty,
            swiftCode: swiftCode.nilIfEmpty,
        )
    }

    /// Creates a `BankAccountItemState` from an API `CipherBankAccountModel`.
    ///
    /// - Parameter model: The API model to convert. When `nil`, an empty state is returned.
    /// - Returns: A `BankAccountItemState` populated from the model.
    ///
    static func fromAPIModel(_ model: CipherBankAccountModel?) -> BankAccountItemState {
        guard let model else { return BankAccountItemState() }
        var state = BankAccountItemState()
        state.accountNumber = model.accountNumber ?? ""
        if let type = model.accountType {
            state.accountType = .custom(type)
        }
        state.bankName = model.bankName ?? ""
        state.bankPhone = model.bankPhone ?? ""
        state.branchNumber = model.branchNumber ?? ""
        state.iban = model.iban ?? ""
        state.nameOnAccount = model.nameOnAccount ?? ""
        state.pin = model.pin ?? ""
        state.routingNumber = model.routingNumber ?? ""
        state.swiftCode = model.swiftCode ?? ""
        return state
    }
}

// MARK: - AddEditBankAccountItemState

/// Protocol describing the add/edit state for a bank account item. Exposed to the add/edit view
/// so the view can bind to fields without depending on the concrete state struct.
///
protocol AddEditBankAccountItemState: Sendable {
    var accountNumber: String { get set }
    var accountType: DefaultableType<BankAccountType> { get set }
    var bankName: String { get set }
    var bankPhone: String { get set }
    var branchNumber: String { get set }
    var iban: String { get set }
    var isAccountNumberVisible: Bool { get set }
    var isPinVisible: Bool { get set }
    var nameOnAccount: String { get set }
    var pin: String { get set }
    var routingNumber: String { get set }
    var swiftCode: String { get set }
}

extension BankAccountItemState: AddEditBankAccountItemState {}

// MARK: - ViewBankAccountItemState

extension BankAccountItemState: ViewBankAccountItemState {
    /// Whether the bank account details section has no user-populated content.
    var isBankAccountDetailsSectionEmpty: Bool {
        bankName.isEmpty
            && nameOnAccount.isEmpty
            && accountType.customValue == nil
            && accountNumber.isEmpty
            && routingNumber.isEmpty
            && branchNumber.isEmpty
            && pin.isEmpty
            && swiftCode.isEmpty
            && iban.isEmpty
            && bankPhone.isEmpty
    }
}
