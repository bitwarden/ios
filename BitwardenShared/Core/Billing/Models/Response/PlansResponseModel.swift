import Networking

// MARK: - PlansResponseModel

/// API response model for the list of subscription plans.
///
struct PlansResponseModel: JSONResponse, Equatable, Sendable {
    // MARK: Properties

    /// The list of plans.
    let data: [PlanResponseModel]
}
