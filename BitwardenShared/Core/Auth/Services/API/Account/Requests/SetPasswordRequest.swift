import Networking

// MARK: - SetPasswordRequest

/// A networking request to get the auto-enroll status for an organization.
///
struct SetPasswordRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of the request.
    var body: SetPasswordRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    var method: HTTPMethod { .post }

    /// The URL path for this request.
    var path: String { "/accounts/set-password" }

    /// The request details to include in the body of the request.
    let requestModel: SetPasswordRequestModel
}
