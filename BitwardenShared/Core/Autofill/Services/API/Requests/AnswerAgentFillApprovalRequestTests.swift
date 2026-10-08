import Networking
import TestHelpers
import Testing

@testable import BitwardenShared

// MARK: - AnswerAgentFillApprovalRequestTests

struct AnswerAgentFillApprovalRequestTests {
    // MARK: Properties

    let subject = AnswerAgentFillApprovalRequest(
        id: "1",
        requestModel: AnswerAgentFillApprovalRequestModel(sealedResponse: "sealed-response"),
    )

    // MARK: Tests

    /// `body` contains the sealed response.
    @Test
    func body() {
        #expect(subject.body == AnswerAgentFillApprovalRequestModel(sealedResponse: "sealed-response"))
    }

    /// `method` returns the correct HTTP method for the request.
    @Test
    func method() {
        #expect(subject.method == .put)
    }

    /// `path` returns the approval's path.
    @Test
    func path() {
        #expect(subject.path == "/agent-fill/approvals/1")
    }

    /// `validate(_:)` throws `alreadyAnswered` for a `409` response.
    @Test
    func validate_conflict() {
        #expect(throws: AnswerAgentFillApprovalRequestError.alreadyAnswered) {
            try subject.validate(.failure(statusCode: 409))
        }
    }

    /// `validate(_:)` throws `expired` for a `410` response.
    @Test
    func validate_gone() {
        #expect(throws: AnswerAgentFillApprovalRequestError.expired) {
            try subject.validate(.failure(statusCode: 410))
        }
    }

    /// `validate(_:)` doesn't throw for a successful response.
    @Test
    func validate_success() throws {
        try subject.validate(.success())
    }

    /// `validate(_:)` leaves other failures to the response handlers.
    @Test
    func validate_otherFailure() throws {
        try subject.validate(.failure(statusCode: 404))
    }
}
