import Networking

// MARK: - PasswordlessLoginRequest

/// The API request sent when attempting to login with device.
///
struct PasswordlessLoginRequest: Request {
    typealias Response = PasswordlessLoginResponseModel

    /// The body of this request.
    let body: PasswordlessLoginRequestModel?

    /// The URL path for this request.
    var path: String = "auth-requests"

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// Creates a new `PasswordlessLoginRequest`.
    ///
    /// - Parameter body: The body of this request.
    ///
    init(body: PasswordlessLoginRequestModel) {
        self.body = body
    }
}
