import Networking

// MARK: - UpdateKdfRequest

/// An API request to update the user's KDF settings.
///
struct UpdateKdfRequest: Request {
    typealias Response = EmptyResponse

    /// The body of the request.
    var body: UpdateKdfRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    let path = "/accounts/kdf"

    /// The request details to include in the body of the request.
    let requestModel: UpdateKdfRequestModel
}
