import Foundation
import Networking

// MARK: - SingleSignOnDetailsRequestModel

/// API request model for getting the single sign on details for a user.
///
struct SingleSignOnDetailsRequestModel: JSONRequestBody {
    // MARK: Static Properties

    static var encoder = JSONEncoder()

    // MARK: Properties

    /// The email of the user to check for single sign on details of.
    let email: String
}
