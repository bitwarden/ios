import Networking

/// An API request to update the user's password.
///
struct UpdatePasswordRequest: Request {
    typealias Response = EmptyResponse

    /// The body of the request.
    var body: UpdatePasswordRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    let path = "/accounts/password"

    /// The request details to include in the body of the request.
    let requestModel: UpdatePasswordRequestModel

    // MARK: Initialization

    /// Initialize an `UpdatePasswordRequest`.
    ///
    /// - Parameter requestModel: The request details to include in the body of the request.
    ///
    init(requestModel: UpdatePasswordRequestModel) {
        self.requestModel = requestModel
    }
}
