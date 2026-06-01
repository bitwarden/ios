import Foundation

// MARK: - BillingError

/// Errors that can occur during billing operations.
///
enum BillingError: Error {
    /// The checkout URL is invalid (e.g., not HTTPS).
    case invalidCheckoutUrl

    /// The portal URL is invalid (e.g., not HTTPS).
    case invalidPortalUrl
}
