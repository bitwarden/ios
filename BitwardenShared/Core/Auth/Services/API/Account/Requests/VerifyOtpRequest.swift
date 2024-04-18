import Networking

// MARK: - VerifyOtpRequest

/// An API request to verify a user's one-time password.
///
struct VerifyOtpRequest: Request {
    typealias Response = EmptyResponse

    /// The body of the request.
    var body: VerifyOtpRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    let path = "/accounts/verify-otp"

    /// The request details to include in the body of the request.
    let requestModel: VerifyOtpRequestModel
}
