import Foundation

/// Actions that can be processed by a `CardAutofillFormProcessor`.
///
enum CardAutofillFormAction: Equatable {
    /// The cardholder name field was updated.
    case cardholderNameChanged(String)

    /// The card number field was updated.
    case cardNumberChanged(String)

    /// The expiration month field was updated.
    case expirationMonthChanged(String)

    /// The expiration year field was updated.
    case expirationYearChanged(String)

    /// The security code field was updated.
    case securityCodeChanged(String)
}
