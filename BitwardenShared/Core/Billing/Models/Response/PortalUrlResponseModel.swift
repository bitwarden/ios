import Foundation
import Networking

// MARK: - PortalUrlResponseModel

/// API response model returned when requesting a Stripe customer portal session.
///
struct PortalUrlResponseModel: JSONResponse, Equatable {
    // MARK: Properties

    /// The Stripe customer portal URL.
    let url: URL
}
