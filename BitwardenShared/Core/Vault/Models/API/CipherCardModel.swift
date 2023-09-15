/// API model for a card cipher.
///
struct CipherCardModel: Codable, Equatable {
    // MARK: Properties

    /// The card's brand.
    let brand: String?

    /// The card's cardholder name.
    let cardholderName: String?

    /// The card's code.
    let code: String?

    /// The card's expiration month.
    let expMonth: String?

    /// The card's expiration year.
    let expYear: String?

    /// The card's number.
    let number: String?
}
