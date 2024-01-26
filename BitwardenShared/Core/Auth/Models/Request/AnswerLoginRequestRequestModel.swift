import Foundation
import Networking

// MARK: - AnswerLoginRequestRequestModel

/// The request body for an answer login request request.
///
struct AnswerLoginRequestRequestModel: JSONRequestBody, Equatable {
    static let encoder = JSONEncoder()

    // MARK: Properties

    /// The app id.
    let deviceIdentifier: String

    /// The encrypted key associated with the request.
    let key: String

    /// The encrypted master password hash, if available.
    let masterPasswordHash: String?

    /// Whether to approve or deny the login request.
    let requestApproved: Bool
}
