import Foundation

extension NumberFormatter {
    /// A formatter for US dollar currency strings using the currency symbol (e.g. "$19.80").
    static let usdCurrency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()

    /// A formatter for US dollar currency strings using the ISO currency code (e.g. "19.80 USD").
    static let usdCurrencyCode: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyISOCode
        formatter.currencyCode = "USD"
        return formatter
    }()
}
