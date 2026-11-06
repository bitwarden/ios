import Networking

// MARK: - CheckoutSessionRequestModel

/// API request model for creating a checkout session for Premium upgrade.
///
struct CheckoutSessionRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The platform identifier (e.g., "ios").
    let platform: String
}
