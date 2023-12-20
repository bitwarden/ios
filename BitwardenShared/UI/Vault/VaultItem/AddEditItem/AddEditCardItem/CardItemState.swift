// MARK: - CardItemState

/// A model for a credit card item.
///
struct CardItemState: Equatable {
    /// The brand of the card.
    var brand: DefaultableType<CardComponent.Brand> = .default

    /// The name of the card holder.
    var cardholderName: String = ""

    /// The number of the card.
    var cardNumber: String = ""

    /// The security code of the card.
    var cardSecurityCode: String = ""

    /// The expiration month of the card.
    var expirationMonth: DefaultableType<CardComponent.Month> = .default

    /// The expiration year of the card.
    var expirationYear: String = ""

    /// The visibility of the security code.
    var isCodeVisible: Bool = false

    /// The visibility of the card number.
    var isNumberVisible: Bool = false
}

// MARK: AddEditCardItemState

extension CardItemState: AddEditCardItemState {}

// MARK: ViewCardItemState

extension CardItemState: ViewCardItemState {}
