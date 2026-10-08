import BitwardenSdk

/// A protocol for a service that handles agent fill tasks. This is similar to
/// `AgentFillClientProtocol` but returns the protocols so they can be mocked for testing.
///
protocol AgentFillClientService: AnyObject {
    /// Returns an object that seals and opens agent fill approval requests and responses.
    ///
    func approvals() -> AgentFillApprovalClientProtocol
}

// MARK: - AgentFillClient

extension AgentFillClient: AgentFillClientService {
    func approvals() -> AgentFillApprovalClientProtocol {
        approvals() as AgentFillApprovalClient
    }
}
