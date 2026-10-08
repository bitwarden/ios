import BitwardenSdk

extension OpenedApprovalRequest {
    static func fixture(
        view: ApprovalRequestView = .fixture(),
        challenge: Challenge = "challenge",
    ) -> OpenedApprovalRequest {
        OpenedApprovalRequest(view: view, challenge: challenge)
    }
}
