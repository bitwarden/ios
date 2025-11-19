// MARK: - ViewCardItemState

/// A protocol for an equatable type that models a Card Item in it's view state.
///
protocol ViewCardItemState: Equatable, Sendable {
    /// The brand of the card.
    var brand: DefaultableType<CardComponent.Brand> { get }

    /// The computed property of the brand of the card, needed special case for `Amex`.
    var brandName: String { get }

    /// The name of the card holder.
    var cardholderName: String { get }

    /// The number of the card.
    var cardNumber: String { get }

    /// The formatted card number with spaces every 4 digits.
    var formattedCardNumber: String { get }

    /// The security code of the card.
    var cardSecurityCode: String { get }

    /// The card's formatted expiration string.
    var expirationString: String { get }

    /// Whether the card details section is empty.
    var isCardDetailsSectionEmpty: Bool { get }

    /// The visibility of the card number.
    var isCodeVisible: Bool { get }

    /// The visibility of the security code.
    var isNumberVisible: Bool { get }
}
