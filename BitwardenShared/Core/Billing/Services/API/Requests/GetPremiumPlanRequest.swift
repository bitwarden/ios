import Networking

// MARK: - GetPremiumPlanRequest

/// A networking request to get the premium subscription plan.
///
struct GetPremiumPlanRequest: Request {
    typealias Response = PremiumPlanResponseModel

    // MARK: Properties

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The URL path for this request.
    var path: String { "/plans/premium" }
}
