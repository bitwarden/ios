import Networking

// MARK: - VerifyUserEmailRequest

/// An API request to verify a user's email.
///
struct VerifyUserEmailRequest: Request {
    typealias Response = EmptyResponse

    /// The body of the request.
    var body: VerifyUserEmailRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    let path = "/accounts/verify-email"

    /// The request details to include in the body of the request.
    let requestModel: VerifyUserEmailRequestModel

    // MARK: Initialization

    /// Initialize an `VerifyUserEmailRequest`.
    ///
    /// - Parameter requestModel: The request details to include in the body of the request.
    ///
    init(requestModel: VerifyUserEmailRequestModel) {
        self.requestModel = requestModel
    }
}
