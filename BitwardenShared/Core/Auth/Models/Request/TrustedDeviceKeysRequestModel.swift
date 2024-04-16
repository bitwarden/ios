// MARK: - TrustedDeviceKeysRequestModel

import Foundation
import Networking

/// A model for keys used in the `TrustedDeviceKeysRequest`.
///
struct TrustedDeviceKeysRequestModel: JSONRequestBody, Equatable {
    // MARK: Properties

    static var encoder = JSONEncoder()

    /// The encrypted private key used in a `TrustedDeviceKeysRequest`.
    let encryptedPrivateKey: String

    /// The encrypted public key used in a `TrustedDeviceKeysRequest`.
    let encryptedPublicKey: String

    /// The encrypted user key used in a `TrustedDeviceKeysRequest`.
    let encryptedUserKey: String
}
