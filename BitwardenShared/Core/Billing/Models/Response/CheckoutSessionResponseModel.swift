import Foundation
import Networking

// MARK: - CheckoutSessionResponseModel

/// API response model returned when creating a premium checkout session.
///
struct CheckoutSessionResponseModel: JSONResponse, Equatable {
    // MARK: Properties

    /// The checkout URL for premium upgrade.
    let checkoutSessionUrl: URL
}
