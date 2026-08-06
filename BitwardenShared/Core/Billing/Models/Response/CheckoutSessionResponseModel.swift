import Foundation
import Networking

// MARK: - CheckoutSessionResponseModel

/// API response model returned when creating a Premium checkout session.
///
struct CheckoutSessionResponseModel: JSONResponse, Equatable {
    // MARK: Properties

    /// The checkout URL for Premium upgrade.
    let checkoutSessionUrl: URL
}
