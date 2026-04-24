// MARK: - AddEditBankAccountItemAction

/// An enum of actions for adding or editing a Bank Account item in its add/edit state.
///
enum AddEditBankAccountItemAction: Equatable, Sendable {
    /// The account number field changed.
    case accountNumberChanged(String)

    /// The account type selection changed.
    case accountTypeChanged(DefaultableType<BankAccountType>)

    /// The bank name field changed.
    case bankNameChanged(String)

    /// The bank contact phone field changed.
    case bankPhoneChanged(String)

    /// The branch number field changed.
    case branchNumberChanged(String)

    /// The IBAN field changed.
    case ibanChanged(String)

    /// The name-on-account field changed.
    case nameOnAccountChanged(String)

    /// The PIN field changed.
    case pinChanged(String)

    /// The routing number field changed.
    case routingNumberChanged(String)

    /// The SWIFT / BIC code field changed.
    case swiftCodeChanged(String)

    /// Toggle for the account number visibility changed.
    case toggleAccountNumberVisibilityChanged(Bool)

    /// Toggle for the PIN visibility changed.
    case togglePinVisibilityChanged(Bool)
}
