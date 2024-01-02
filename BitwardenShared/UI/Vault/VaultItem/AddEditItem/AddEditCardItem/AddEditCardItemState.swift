// MARK: AddEditCardItemState

/// A protocol for a sendable type that models a Card Item in it's add/edit state.
///
protocol AddEditCardItemState: Equatable, Sendable {
    /// The brand of the card.
    var brand: DefaultableType<CardComponent.Brand> { get set }

    /// The name of the card holder.
    var cardholderName: String { get set }

    /// The number of the card.
    var cardNumber: String { get set }

    /// The security code of the card.
    var cardSecurityCode: String { get set }

    /// The expiration month of the card.
    var expirationMonth: DefaultableType<CardComponent.Month> { get set }

    /// The expiration year of the card.
    var expirationYear: String { get set }

    /// The visibility of the security code.
    var isCodeVisible: Bool { get set }

    /// The visibility of the card number.
    var isNumberVisible: Bool { get set }
}
