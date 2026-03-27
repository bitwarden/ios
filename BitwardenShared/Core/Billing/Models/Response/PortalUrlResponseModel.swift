import Foundation
import Networking

// MARK: - PortalUrlResponseModel

/// API response model returned when requesting a customer portal session.
///
struct PortalUrlResponseModel: JSONResponse, Equatable {
    // MARK: Properties

    /// The customer portal URL.
    let url: URL
}
