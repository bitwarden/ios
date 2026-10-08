import BitwardenKit
import Foundation
import Networking

// MARK: - AgentFillApprovalRecord

/// A server record for an agent fill approval request, as returned by the `/agent-fill/approvals`
/// endpoints.
///
struct AgentFillApprovalRecord: Equatable, JSONResponse, Sendable {
    // MARK: Types

    /// The status of an approval record, derived by the server on read.
    enum Status: String, Codable, Equatable, Sendable {
        /// The record has a sealed response.
        case answered

        /// The record has no response and its expiration date has passed.
        case expired

        /// The record is waiting for an answer.
        case pending
    }

    // MARK: Static Properties

    static let decoder = JSONDecoder.pascalOrSnakeCaseDecoder

    // MARK: Properties

    /// The date the request was created.
    let creationDate: Date

    /// The date the request expires.
    let expirationDate: Date

    /// The ID of the approval request.
    let id: String

    /// The ID of the device that created the request.
    let requestDeviceId: String

    /// The ID of the device that answered the request, if any.
    let responseDeviceId: String?

    /// The date the request was answered, if any.
    let responseDate: Date?

    /// The sealed request, which only the user's SDK client can open.
    let sealedRequest: String

    /// The sealed response, if the request has been answered.
    let sealedResponse: String?

    /// The status of the record.
    let status: Status

    // MARK: Computed Properties

    /// Whether the record has already been answered.
    var isAnswered: Bool {
        sealedResponse != nil || status == .answered
    }

    /// Whether the record's expiration date has passed without an answer.
    var isExpired: Bool {
        !isAnswered && (status == .expired || expirationDate <= Date())
    }
}
