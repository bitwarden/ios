import Networking

/// Data model for performing a identity token refresh request.
///
struct IdentityTokenRefreshRequest: Request {
    typealias Response = IdentityTokenRefreshResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: IdentityTokenRefreshRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method = HTTPMethod.post

    /// The URL path for this request.
    let path = "/connect/token"

    /// The request details to include in the body of the request.
    let requestModel: IdentityTokenRefreshRequestModel

    // MARK: Initialization

    /// Initialize an `IdentityTokenRefreshRequest`.
    ///
    /// - Parameter refreshToken: The refresh token used to get a new access token.
    ///
    init(refreshToken: String) {
        requestModel = IdentityTokenRefreshRequestModel(refreshToken: refreshToken)
    }
}
