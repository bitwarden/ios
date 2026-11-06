// MARK: - ViewBankAccountItemAction

/// An enum of actions for viewing a bank account item.
///
enum ViewBankAccountItemAction: Equatable {
    /// Toggle for account number visibility changed.
    case toggleAccountNumberVisibilityChanged(Bool)

    /// Toggle for IBAN visibility changed.
    case toggleIbanVisibilityChanged(Bool)

    /// Toggle for PIN visibility changed.
    case togglePinVisibilityChanged(Bool)
}
