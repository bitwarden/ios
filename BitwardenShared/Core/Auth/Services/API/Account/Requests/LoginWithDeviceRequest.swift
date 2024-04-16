import Networking

// MARK: - LoginWithDeviceRequest

/// The API request sent to initiate a login with device request.
///
struct LoginWithDeviceRequest: Request {
    typealias Response = LoginRequest

    /// The body of this request.
    let body: LoginWithDeviceRequestModel?

    /// A dictionary of HTTP headers to be sent in the request.
    let headers: [String: String]

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The type of auth request.
    let requestType: AuthRequestType

    /// The URL path for this request.
    var path: String {
        requestType == AuthRequestType.adminApproval ? "/auth-requests/admin-request" : "/auth-requests"
    }

    /// Creates a new `LoginWithDeviceRequest`.
    ///
    /// - Parameter body: The body of this request.
    ///
    init(body: LoginWithDeviceRequestModel) {
        self.body = body
        requestType = body.type
        headers = ["Device-Identifier": body.deviceIdentifier]
    }
}
