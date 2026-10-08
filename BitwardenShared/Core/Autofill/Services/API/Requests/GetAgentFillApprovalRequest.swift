import Foundation
import Networking

// MARK: - GetAgentFillApprovalRequest

/// A request for getting an agent fill approval record.
///
struct GetAgentFillApprovalRequest: Request {
    typealias Response = AgentFillApprovalRecord

    // MARK: Properties

    /// The ID of the approval request to get.
    let id: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The URL path for this request.
    var path: String { "/agent-fill/approvals/\(id)" }
}
