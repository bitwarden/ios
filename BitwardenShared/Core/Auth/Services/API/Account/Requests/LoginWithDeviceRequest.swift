import Networking

// MARK: - LoginWithDeviceRequest

/// The API request sent to initiate a login with device request.
///
struct LoginWithDeviceRequest: Request {
    typealias Response = LoginRequest

    /// The body of this request.
    let body: LoginWithDeviceRequestModel?

    /// The URL path for this request.
    var path: String = "auth-requests"

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// Creates a new `LoginWithDeviceRequest`.
    ///
    /// - Parameter body: The body of this request.
    ///
    init(body: LoginWithDeviceRequestModel) {
        self.body = body
    }
}
