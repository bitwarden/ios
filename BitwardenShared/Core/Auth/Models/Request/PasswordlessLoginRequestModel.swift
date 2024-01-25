import Foundation
import Networking

// MARK: - PasswordlessLoginRequestModel

/// A request for sending a passwordless login request, which can be approved/denied on the user's
/// second device.
///
struct PasswordlessLoginRequestModel: JSONRequestBody, Equatable {
    // MARK: Static Properties

    static let encoder = JSONEncoder()

    /// The user's email.
    var email: String

    /// The public key used in the request.
    var publicKey: String

    /// The user's device ID.
    var deviceIdentifier: String

    /// The access code used in the request.
    var accessCode: String

    /// The type of request being made.
    var type: Int

    /// The fingerprint phrase used in the request.
    var fingerprintPhrase: String
}
