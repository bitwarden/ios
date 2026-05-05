// MARK: - ScannedCardData

/// Parsed card details extracted from a camera scan.
///
struct ScannedCardData: Equatable, Sendable {
    /// The card number (digits only, 13–19 characters).
    var cardNumber: String?

    /// The expiration month as an integer (1–12).
    var expirationMonth: Int?

    /// The expiration year as a 4-digit string (e.g. "2028").
    var expirationYear: String?
}
