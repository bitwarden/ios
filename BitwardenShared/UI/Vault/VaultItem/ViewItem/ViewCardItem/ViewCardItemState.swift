// MARK: - ViewCardItemState

/// A protocol for an equatable type that models a Card Item in it's view state.
///
protocol ViewCardItemState: Equatable {
    /// The brand of the card.
    var brand: DefaultableType<CardComponent.Brand> { get }

    /// The computed property of  the brand of the card, needed special case for `Amex`.
    var brandName: String { get }

    /// The name of the card holder.
    var cardholderName: String { get }

    /// The number of the card.
    var cardNumber: String { get }

    /// The security code of the card.
    var cardSecurityCode: String { get }

    /// The expiration month of the card.
    var expirationMonth: DefaultableType<CardComponent.Month> { get }

    /// The expiration year of the card.
    var expirationYear: String { get }

    /// The visibility of the card number.
    var isCodeVisible: Bool { get }

    /// The visibility of the security code.
    var isNumberVisible: Bool { get }
}
