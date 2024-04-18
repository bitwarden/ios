import Networking

/// An API request to request a one-time password for the user.
///
struct RequestOtpRequest: Request {
    typealias Response = EmptyResponse

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    let path = "/accounts/request-otp"
}
