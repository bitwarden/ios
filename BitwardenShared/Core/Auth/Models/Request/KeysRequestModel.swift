import BitwardenSdk
import Foundation
import Networking

// MARK: - KeysRequestModel

/// A model used to set account keys
///
struct KeysRequestModel: Codable, Equatable {
    // MARK: Properties

    /// The encrypted private key used to set account keys`.
    let encryptedPrivateKey: String

    /// The public key used to set account keys.
    var publicKey: String?
}

extension KeysRequestModel {
    // MARK: Initialization

    /// Initialize `KeysRequestModel` from a `RsaKeyPair`.
    ///
    /// - Parameter keyPair: The key pair used to initialize a `KeysRequestModel`.
    ///
    init(keyPair: RsaKeyPair) {
        self.init(encryptedPrivateKey: keyPair.private, publicKey: keyPair.public)
    }
}

extension KeysRequestModel: JSONRequestBody {
    static let encoder = JSONEncoder()
}
