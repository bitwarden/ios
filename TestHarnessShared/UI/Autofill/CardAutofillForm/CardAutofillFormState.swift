import Foundation

/// The state for the card autofill form test screen.
///
struct CardAutofillFormState: Equatable {
    // MARK: Properties

    /// The cardholder name field value.
    var cardholderName: String = ""

    /// The card number field value.
    var cardNumber: String = ""

    /// The expiration month field value.
    var expirationMonth: String = ""

    /// The expiration year field value.
    var expirationYear: String = ""

    /// The security code field value.
    var securityCode: String = ""

    /// The title of the screen.
    var title: String = Localizations.cardAutofillForm

    /// Whether any field has a non-empty value.
    var hasAnyValue: Bool {
        !cardholderName.isEmpty
            || !cardNumber.isEmpty
            || !expirationMonth.isEmpty
            || !expirationYear.isEmpty
            || !securityCode.isEmpty
    }
}
