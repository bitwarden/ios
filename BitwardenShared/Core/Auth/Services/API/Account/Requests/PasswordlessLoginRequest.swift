import Networking

struct PasswordlessLoginRequest: Request {
    typealias Response = PasswordlessLoginResponseModel

    let body: PasswordlessLoginRequestModel?

    var path: String = "auth-requests"

    let method: HTTPMethod = .post

    /// Creates a new `PasswordlessLoginRequest`.
    ///
    /// - Parameter body: The body of this request.
    ///
    init(body: PasswordlessLoginRequestModel) {
        self.body = body
    }
}
