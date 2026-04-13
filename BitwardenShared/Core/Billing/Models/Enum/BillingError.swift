import Foundation

// MARK: - BillingError

/// Errors that can occur during billing operations.
///
enum BillingError: LocalizedError {
    /// The checkout URL is invalid (e.g., not HTTPS).
    case invalidCheckoutUrl

    /// Unable to open the checkout URL in the browser.
    case unableToOpenCheckout

    var errorDescription: String? {
        switch self {
        case .invalidCheckoutUrl,
             .unableToOpenCheckout:
            // TODO: PM-33856 Handle payment errors
            nil
        }
    }
}
