import Networking

// MARK: - GetPortalUrlRequest

/// A networking request to create a customer portal session for managing
/// the premium subscription.
///
struct GetPortalUrlRequest: Request {
    typealias Response = PortalUrlResponseModel

    // MARK: Properties

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    let path = "/account/billing/vnext/portal-session"
}
