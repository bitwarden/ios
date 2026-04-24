// MARK: - ViewBankAccountItemAction

/// An enum of actions for viewing a Bank Account item in its view state.
///
enum ViewBankAccountItemAction: Equatable, Sendable {
    /// Toggle for the account number visibility changed.
    case toggleAccountNumberVisibilityChanged(Bool)

    /// Toggle for the PIN visibility changed.
    case togglePinVisibilityChanged(Bool)
}
