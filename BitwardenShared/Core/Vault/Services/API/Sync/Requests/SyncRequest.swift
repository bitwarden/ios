import Networking

/// Data model for performing a sync request.
///
struct SyncRequest: Request {
    typealias Response = SyncResponseModel

    /// The HTTP method for this request.
    let method = HTTPMethod.get

    /// The URL path for this request.
    let path = "/sync"
}
