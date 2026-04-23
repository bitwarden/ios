import Foundation

extension NumberFormatter {
    /// A formatter for US dollar currency strings (e.g. "$19.80").
    static let usdCurrency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}
