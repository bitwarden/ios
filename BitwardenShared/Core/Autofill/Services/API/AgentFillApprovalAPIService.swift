import Foundation

// MARK: - AgentFillApprovalAnswerResult

/// The result of sending an answer for an agent fill approval request.
///
enum AgentFillApprovalAnswerResult: Equatable {
    /// The answer was recorded.
    case answered

    /// Another device already answered the request.
    case alreadyAnswered

    /// The request expired before it was answered.
    case expired
}

// MARK: - AgentFillApprovalAPIService

/// A protocol for an API service used to make agent fill approval requests.
///
protocol AgentFillApprovalAPIService { // sourcery: AutoMockable
    /// Sends the sealed answer to an agent fill approval request.
    ///
    /// - Parameters:
    ///   - id: The ID of the approval request.
    ///   - sealedResponse: The sealed response produced by the SDK.
    /// - Returns: Whether the answer was recorded, or the request was already answered or expired.
    ///
    func answerAgentFillApproval(_ id: String, sealedResponse: String) async throws -> AgentFillApprovalAnswerResult

    /// Gets an agent fill approval record.
    ///
    /// - Parameter id: The ID of the approval request.
    /// - Returns: The approval record.
    ///
    func getAgentFillApproval(_ id: String) async throws -> AgentFillApprovalRecord
}

// MARK: - APIService

extension APIService: AgentFillApprovalAPIService {
    func answerAgentFillApproval(
        _ id: String,
        sealedResponse: String,
    ) async throws -> AgentFillApprovalAnswerResult {
        do {
            _ = try await apiService.send(
                AnswerAgentFillApprovalRequest(
                    id: id,
                    requestModel: AnswerAgentFillApprovalRequestModel(sealedResponse: sealedResponse),
                ),
            )
            return .answered
        } catch AnswerAgentFillApprovalRequestError.alreadyAnswered {
            return .alreadyAnswered
        } catch AnswerAgentFillApprovalRequestError.expired {
            return .expired
        }
    }

    func getAgentFillApproval(_ id: String) async throws -> AgentFillApprovalRecord {
        try await apiService.send(GetAgentFillApprovalRequest(id: id))
    }
}
