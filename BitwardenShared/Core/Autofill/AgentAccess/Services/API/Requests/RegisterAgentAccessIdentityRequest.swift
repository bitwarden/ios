import Foundation
import Networking

// MARK: - RegisterAgentAccessIdentityRequestBody

/// Data model for the body of a register Agent Access identity request.
///
struct RegisterAgentAccessIdentityRequestBody: JSONRequestBody {
    /// The 64 character lowercase hex identity fingerprint.
    let fingerprint: String
}

// MARK: - RegisterAgentAccessIdentityRequest

/// Data model for performing a register Agent Access identity request.
///
struct RegisterAgentAccessIdentityRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of this request.
    var body: RegisterAgentAccessIdentityRequestBody? { requestBody }

    /// The HTTP method for this request.
    var method: HTTPMethod { .put }

    /// The URL path for this request.
    var path: String { "/agent-access/identities" }

    /// The body of the request.
    let requestBody: RegisterAgentAccessIdentityRequestBody
}
