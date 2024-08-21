import Foundation
import Networking

// MARK: - ResendEmailCodeRequestModel

/// API request model for re-sending the two-factor verification code email.
///
struct ResendEmailCodeRequestModel: JSONRequestBody {
    // MARK: Static Properties

    static let encoder = JSONEncoder()

    // MARK: Properties

    /// The device identifier.
    let deviceIdentifier: String

    /// The email to send the verification code to.
    let email: String

    /// The master password hash, if available.
    let masterPasswordHash: String?

    /// The single-sign on token, if available.
    let ssoEmail2FaSessionToken: String?
}
