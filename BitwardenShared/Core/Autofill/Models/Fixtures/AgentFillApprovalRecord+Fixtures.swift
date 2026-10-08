import Foundation

@testable import BitwardenShared

extension AgentFillApprovalRecord {
    static func fixture(
        creationDate: Date = Date(year: 2026, month: 10, day: 8, hour: 9, minute: 0),
        expirationDate: Date = Date(year: 2999, month: 1, day: 1),
        id: String = "approval-1",
        requestDeviceId: String = "device-1",
        responseDeviceId: String? = nil,
        responseDate: Date? = nil,
        sealedRequest: String = "sealed-request",
        sealedResponse: String? = nil,
        status: Status = .pending,
    ) -> AgentFillApprovalRecord {
        AgentFillApprovalRecord(
            creationDate: creationDate,
            expirationDate: expirationDate,
            id: id,
            requestDeviceId: requestDeviceId,
            responseDeviceId: responseDeviceId,
            responseDate: responseDate,
            sealedRequest: sealedRequest,
            sealedResponse: sealedResponse,
            status: status,
        )
    }
}
