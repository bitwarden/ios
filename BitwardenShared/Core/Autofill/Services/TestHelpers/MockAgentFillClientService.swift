import BitwardenSdk
import BitwardenSdkMocks

@testable import BitwardenShared

class MockAgentFillClientService: AgentFillClientService {
    var clientApprovals = MockAgentFillApprovalClientProtocol()

    func approvals() -> AgentFillApprovalClientProtocol {
        clientApprovals
    }
}
