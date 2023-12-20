// MARK: AddEditCardItemAction

/// An enum of actiosn for adding or editing a card Item in it's add/edit state.
///
enum AddEditCardItemAction: Equatable {
    /// The brand of the card changed.
    case brandChanged(DefaultableType<CardComponent.Brand>)

    /// The name of the card holder changed.
    case cardholderNameChanged(String)

    /// The number of the card changed.
    case cardNumberChanged(String)

    /// The security code of the card changed.
    case cardSecurityCodeChanged(String)

    /// The expiration month of the card changed.
    case expirationMonthChanged(DefaultableType<CardComponent.Month>)

    /// The expiration year of the card changed.
    case expirationYearChanged(String)

    /// Toggle for code visibility changed.
    case toggleCodeVisibilityChanged(Bool)

    /// Toggle for number visibility changed.
    case toggleNumberVisibilityChanged(Bool)
}
