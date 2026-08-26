import BitwardenKit

// MARK: - AddEditBankAccountItemAction

/// An enum of actions for adding or editing a bank account item in its add/edit state.
///
enum AddEditBankAccountItemAction: Equatable, Sendable {
    /// The account number of the bank account changed.
    case accountNumberChanged(String)

    /// The type of the bank account changed.
    case accountTypeChanged(DefaultableType<BankAccountType>)

    /// The contact phone number for the bank changed.
    case bankContactPhoneChanged(String)

    /// The name of the bank changed.
    case bankNameChanged(String)

    /// The branch number of the bank account changed.
    case branchNumberChanged(String)

    /// The IBAN of the bank account changed.
    case ibanChanged(String)

    /// The name on the bank account changed.
    case nameOnAccountChanged(String)

    /// The PIN of the bank account changed.
    case pinChanged(String)

    /// The routing number of the bank account changed.
    case routingNumberChanged(String)

    /// The SWIFT/BIC code of the bank changed.
    case swiftCodeChanged(String)

    /// Toggle for account number visibility changed.
    case toggleAccountNumberVisibilityChanged(Bool)

    /// Toggle for IBAN visibility changed.
    case toggleIbanVisibilityChanged(Bool)

    /// Toggle for PIN visibility changed.
    case togglePinVisibilityChanged(Bool)
}
