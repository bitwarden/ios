import Networking

// MARK: - DevicesListRequest

/// A request for retrieving the list of devices for the current user.
///
struct DevicesListRequest: Request {
    typealias Response = DevicesListResponse

    var method: HTTPMethod { .get }

    var path: String { "/devices" }
}
