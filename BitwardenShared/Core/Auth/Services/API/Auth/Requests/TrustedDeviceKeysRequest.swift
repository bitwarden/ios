import Foundation
import Networking

// MARK: - TrustedDeviceKeysRequest

/// A request for answering a login requests.
///
struct TrustedDeviceKeysRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of the request.
    var body: TrustedDeviceKeysRequestModel? { requestModel }

    /// The id of the login request to answer.
    let deviceIdentifier: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .put }

    /// The URL path for this request.
    var path: String { "/devices/\(deviceIdentifier)/keys" }

    /// The request details to include in the body of the request.
    let requestModel: TrustedDeviceKeysRequestModel
}
