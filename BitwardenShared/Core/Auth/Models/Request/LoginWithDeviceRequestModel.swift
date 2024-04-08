import Foundation
import Networking

// MARK: - LoginWithDeviceRequestModel

/// A request for sending a login with device request, which can be approved/denied on the user's
/// other device.
///
struct LoginWithDeviceRequestModel: JSONRequestBody, Equatable {
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
    var type: AuthRequestType

    /// The fingerprint phrase used in the request.
    var fingerprintPhrase: String
}
