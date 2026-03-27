import Networking

// MARK: - CreateCheckoutSessionRequest

/// A networking request to create a checkout session for premium upgrade.
///
struct CreateCheckoutSessionRequest: Request {
    typealias Response = CheckoutSessionResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: CheckoutSessionRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    let path = "/account/billing/vnext/premium/checkout"

    /// The request details to include in the body of the request.
    let requestModel: CheckoutSessionRequestModel

    // MARK: Initialization

    /// Initialize a `CreateCheckoutSessionRequest`.
    ///
    /// - Parameter requestModel: The request details to include in the body of the request.
    ///
    init(requestModel: CheckoutSessionRequestModel) {
        self.requestModel = requestModel
    }
}
