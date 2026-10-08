import Foundation
import Networking

// MARK: - AnswerAgentFillApprovalRequestModel

/// The request body for answering an agent fill approval request.
///
struct AnswerAgentFillApprovalRequestModel: JSONRequestBody, Equatable {
    static let encoder = JSONEncoder()

    // MARK: Properties

    /// The sealed response, produced by the SDK.
    let sealedResponse: String
}
