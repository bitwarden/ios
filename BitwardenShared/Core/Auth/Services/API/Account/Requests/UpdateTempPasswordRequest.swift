import Networking

/// An API request to update the user's temporary password.
///
struct UpdateTempPasswordRequest: Request {
    typealias Response = EmptyResponse

    /// The body of the request.
    var body: UpdateTempPasswordRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method: HTTPMethod = .put

    /// The URL path for this request.
    let path = "/accounts/update-temp-password"

    /// The request details to include in the body of the request.
    let requestModel: UpdateTempPasswordRequestModel

    // MARK: Initialization

    /// Initialize an `UpdateTempPasswordRequest`.
    ///
    /// - Parameter requestModel: The request details to include in the body of the request.
    ///
    init(requestModel: UpdateTempPasswordRequestModel) {
        self.requestModel = requestModel
    }
}
