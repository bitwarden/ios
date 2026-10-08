import Testing

@testable import BitwardenShared

// MARK: - GetAgentFillApprovalRequestTests

struct GetAgentFillApprovalRequestTests {
    // MARK: Tests

    /// `method` returns the correct HTTP method for the request.
    @Test
    func method() {
        #expect(GetAgentFillApprovalRequest(id: "1").method == .get)
    }

    /// `path` returns the approval's path.
    @Test
    func path() {
        #expect(GetAgentFillApprovalRequest(id: "1").path == "/agent-fill/approvals/1")
    }
}
