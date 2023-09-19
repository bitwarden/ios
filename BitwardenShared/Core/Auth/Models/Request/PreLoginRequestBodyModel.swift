import Foundation
import Networking

// MARK: - PreLoginRequestModel

/// The request body for a pre login request.
///
struct PreLoginRequestBodyModel: JSONRequestBody, Equatable {
    // MARK: Static Properties

    static let encoder = JSONEncoder()

    // MARK: Properties

    /// The user's email address.
    var email: String
}
