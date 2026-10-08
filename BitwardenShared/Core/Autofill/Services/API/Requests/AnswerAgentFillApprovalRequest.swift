import Foundation
import Networking

// MARK: - AnswerAgentFillApprovalRequestError

/// Errors thrown from validating an `AnswerAgentFillApprovalRequest` response.
///
enum AnswerAgentFillApprovalRequestError: Error, Equatable {
    /// The approval request already has a response (`409`).
    case alreadyAnswered

    /// The approval request's expiration date has passed (`410`).
    case expired
}

// MARK: - AnswerAgentFillApprovalRequest

/// A request for answering an agent fill approval request.
///
struct AnswerAgentFillApprovalRequest: Request {
    typealias Response = AgentFillApprovalRecord

    // MARK: Properties

    /// The body of the request.
    var body: AnswerAgentFillApprovalRequestModel? { requestModel }

    /// The ID of the approval request to answer.
    let id: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .put }

    /// The URL path for this request.
    var path: String { "/agent-fill/approvals/\(id)" }

    /// The sealed response to send.
    let requestModel: AnswerAgentFillApprovalRequestModel

    // MARK: Request

    func validate(_ response: HTTPResponse) throws {
        switch response.statusCode {
        case 409:
            throw AnswerAgentFillApprovalRequestError.alreadyAnswered
        case 410:
            throw AnswerAgentFillApprovalRequestError.expired
        default:
            break
        }
    }
}
