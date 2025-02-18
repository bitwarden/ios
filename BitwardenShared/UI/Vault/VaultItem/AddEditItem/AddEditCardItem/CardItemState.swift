import BitwardenSdk

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

extension CardItemState {
    var cardView: CardView {
        .init(
            cardholderName: cardholderName.nilIfEmpty,
            expMonth: {
                guard case let .custom(month) = expirationMonth else { return nil }
                return "\(month.rawValue)"
            }(),
            expYear: expirationYear.nilIfEmpty,
            code: cardSecurityCode.nilIfEmpty,
            brand: {
                guard case let .custom(brand) = brand else { return nil }
                return brand.rawValue
            }(),
            number: cardNumber.nilIfEmpty
        )
    }
}

// MARK: AddEditCardItemState

extension CardItemState: AddEditCardItemState {}

// MARK: ViewCardItemState

extension CardItemState: ViewCardItemState {
    /// The computed property of the brand of the card, needed special case for `Amex`.
    var brandName: String {
        if case .custom(.americanExpress) = brand {
            return "Amex"
        }
        return brand.localizedName
    }

    /// The card's formatted expiration string.
    var expirationString: String {
        var strings = [String]()
        if case let .custom(month) = expirationMonth {
            strings.append("\(month.rawValue)")
        }
        if !expirationYear.isEmpty {
            strings.append(expirationYear)
        }
        return strings.joined(separator: "/")
    }

    /// Whether the card details section is empty.
    var isCardDetailsSectionEmpty: Bool {
        cardholderName.isEmpty
            && cardNumber.isEmpty
            && brand.customValue == nil
            && expirationString.isEmpty
            && cardSecurityCode.isEmpty
    }
}
