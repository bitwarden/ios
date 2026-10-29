import Foundation

@testable import BitwardenShared

extension ScannedCardData {
    static func fixture(
        cardNumber: String? = "4111111111111111",
        expirationMonth: Int? = 12,
        expirationYear: String? = "2028",
    ) -> ScannedCardData {
        self.init(
            cardNumber: cardNumber,
            expirationMonth: expirationMonth,
            expirationYear: expirationYear,
        )
    }
}
