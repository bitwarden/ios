// MARK: - BitwardenDiscountType

/// The type of discounts Bitwarden supports.
///
enum BitwardenDiscountType: String, Codable, Equatable, Sendable {
    /// A fixed-amount discount.
    case amountOff = "amount-off"

    /// A percentage discount.
    case percentOff = "percent-off"
}
