import Foundation
import Networking

// MARK: - PasswordHintRequestModel

/// The request body for a password hint request.
///
struct PasswordHintRequestModel: JSONRequestBody, Equatable {
    // MARK: Static Properties

    static let encoder = JSONEncoder()

    // MARK: Properties

    /// The user's email address.
    var email: String
}
