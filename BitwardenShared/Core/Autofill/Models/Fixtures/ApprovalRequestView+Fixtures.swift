import BitwardenSdk

extension ApprovalRequestView {
    static func fixture(
        cipherType: ApprovalCipherType = .login,
        tabUrl: String = "https://delta.com/login",
        domain: String = "delta.com",
        connectionName: String = "Claude Desktop",
        browserName: String = "Chrome",
    ) -> ApprovalRequestView {
        ApprovalRequestView(
            cipherType: cipherType,
            tabUrl: tabUrl,
            domain: domain,
            connectionName: connectionName,
            browserName: browserName,
        )
    }
}
