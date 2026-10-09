import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AgentFillApprovalRecordTests

struct AgentFillApprovalRecordTests {
    // MARK: Tests

    /// `init(from:)` decodes a record returned by the server.
    @Test
    func decode() throws {
        let json = """
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
        """

        let subject = try AgentFillApprovalRecord.decoder.decode(
            AgentFillApprovalRecord.self,
            from: Data(json.utf8),
        )

        #expect(subject.id == "approval-1")
        #expect(subject.requestDeviceId == "device-1")
        #expect(subject.sealedRequest == "sealed-request")
        #expect(subject.sealedResponse == nil)
        #expect(subject.status == .pending)
        #expect(subject.expirationDate.timeIntervalSince(subject.creationDate) == 5 * 60)
    }

    /// `isAnswered` is `true` when the record has a sealed response.
    @Test
    func isAnswered_sealedResponse() {
        #expect(AgentFillApprovalRecord.fixture(sealedResponse: "sealed-response").isAnswered)
    }

    /// `isAnswered` is `true` when the server reports the record as answered.
    @Test
    func isAnswered_status() {
        #expect(AgentFillApprovalRecord.fixture(status: .answered).isAnswered)
    }

    /// `isAnswered` is `false` for a pending record.
    @Test
    func isAnswered_pending() {
        #expect(!AgentFillApprovalRecord.fixture().isAnswered)
    }

    /// `isExpired` is `true` when the expiration date has passed without an answer.
    @Test
    func isExpired_pastExpirationDate() {
        #expect(AgentFillApprovalRecord.fixture(expirationDate: Date(year: 2020, month: 1, day: 1)).isExpired)
    }

    /// `isExpired` is `true` when the server reports the record as expired.
    @Test
    func isExpired_status() {
        #expect(AgentFillApprovalRecord.fixture(status: .expired).isExpired)
    }

    /// `isExpired` is `false` for an answered record, even past its expiration date.
    @Test
    func isExpired_answered() {
        let subject = AgentFillApprovalRecord.fixture(
            expirationDate: Date(year: 2020, month: 1, day: 1),
            sealedResponse: "sealed-response",
        )
        #expect(!subject.isExpired)
    }

    /// `isExpired` is `false` for a pending record.
    @Test
    func isExpired_pending() {
        #expect(!AgentFillApprovalRecord.fixture().isExpired)
    }
}
