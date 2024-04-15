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

extension KeysRequestModel: JSONRequestBody {
    static let encoder = JSONEncoder()
}
