import Networking

// MARK: - GetPlansRequest

/// A networking request to get the list of subscription plans.
///
struct GetPlansRequest: Request {
    typealias Response = PlansResponseModel

    // MARK: Properties

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The URL path for this request.
    var path: String { "/plans" }
}
