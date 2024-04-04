import Foundation
import Networking

// MARK: - KeysRequestModel

/// A model for keys used in the `CreateAccountRequest`.
///
struct KeysRequestModel: Codable, Equatable {
    // MARK: Properties

    /// The encrypted private key used in a `CreateAccountRequest`.
    let encryptedPrivateKey: String

    /// The public key used in a `CreateAccountRequest`.
    var publicKey: String?
}

extension KeysRequestModel: JSONRequestBody {
    static let encoder = JSONEncoder()
}
