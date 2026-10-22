import Foundation
import Networking

// MARK: - UnregisterAgentAccessIdentityRequest

/// Data model for performing an unregister Agent Access identity request.
///
struct UnregisterAgentAccessIdentityRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The 64 character lowercase hex identity fingerprint.
    let fingerprint: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .delete }

    /// The URL path for this request.
    var path: String { "/agent-access/identities/\(fingerprint)" }
}
