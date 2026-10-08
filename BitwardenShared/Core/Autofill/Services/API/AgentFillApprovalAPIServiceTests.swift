import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared

// MARK: - AgentFillApprovalAPIServiceTests

@MainActor
struct AgentFillApprovalAPIServiceTests {
    // MARK: Properties

    let client: MockHTTPClient
    let subject: AgentFillApprovalAPIService

    // MARK: Initialization

    init() {
        client = MockHTTPClient()
        subject = APIService(client: client)
    }

    // MARK: Tests

    /// `answerAgentFillApproval(_:sealedResponse:)` sends the sealed response and returns `answered`.
    @Test
    func answerAgentFillApproval() async throws {
        client.result = .httpSuccess(testData: .agentFillApproval)

        let result = try await subject.answerAgentFillApproval("approval-1", sealedResponse: "sealed-response")

        #expect(result == .answered)
        let request = try #require(client.requests.last)
        #expect(request.method == .put)
        #expect(request.url.relativePath == "/api/agent-fill/approvals/approval-1")
        #expect(request.body != nil)
    }

    /// `answerAgentFillApproval(_:sealedResponse:)` returns `alreadyAnswered` for a `409` response.
    @Test
    func answerAgentFillApproval_conflict() async throws {
        client.result = .httpFailure(statusCode: 409)

        let result = try await subject.answerAgentFillApproval("approval-1", sealedResponse: "sealed-response")

        #expect(result == .alreadyAnswered)
    }

    /// `answerAgentFillApproval(_:sealedResponse:)` returns `expired` for a `410` response.
    @Test
    func answerAgentFillApproval_gone() async throws {
        client.result = .httpFailure(statusCode: 410)

        let result = try await subject.answerAgentFillApproval("approval-1", sealedResponse: "sealed-response")

        #expect(result == .expired)
    }

    /// `answerAgentFillApproval(_:sealedResponse:)` throws other failures.
    @Test
    func answerAgentFillApproval_error() async {
        client.result = .httpFailure(BitwardenTestError.example)

        await #expect(throws: BitwardenTestError.example) {
            try await subject.answerAgentFillApproval("approval-1", sealedResponse: "sealed-response")
        }
    }

    /// `getAgentFillApproval(_:)` sends the request and decodes the record.
    @Test
    func getAgentFillApproval() async throws {
        client.result = .httpSuccess(testData: .agentFillApproval)

        let record = try await subject.getAgentFillApproval("approval-1")

        #expect(record.id == "approval-1")
        #expect(record.sealedRequest == "sealed-request")
        let request = try #require(client.requests.last)
        #expect(request.method == .get)
        #expect(request.url.relativePath == "/api/agent-fill/approvals/approval-1")
    }
}
