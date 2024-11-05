import Foundation
import Networking

// MARK: - SingleSignOnDomainsVerifiedRequestModel

/// API request model for getting the single sign on verified domains of a user from their email.
///
struct SingleSignOnDomainsVerifiedRequestModel: JSONRequestBody {
    // MARK: Static Properties

    static let encoder = JSONEncoder()

    // MARK: Properties

    /// The email of the user to check for single sign on details of.
    let email: String
}
