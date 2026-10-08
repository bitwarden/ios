import Foundation
import TestHelpers

// swiftlint:disable missing_docs

public extension APITestData {
    // MARK: Agent Fill Approval

    static let agentFillApproval = APITestData(data: Data("""
    {
        "id": "approval-1",
        "requestDeviceId": "device-1",
        "sealedRequest": "sealed-request",
        "sealedResponse": null,
        "responseDeviceId": null,
        "creationDate": "2026-10-08T09:00:00Z",
        "expirationDate": "2026-10-08T09:05:00Z",
        "responseDate": null,
        "status": "pending"
    }
    """.utf8))
}

// swiftlint:enable missing_docs
