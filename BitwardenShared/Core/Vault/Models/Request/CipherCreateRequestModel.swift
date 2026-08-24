import BitwardenSdk
import Foundation
import Networking

/// API request model for adding or updating a cipher in a collection.
///
struct CipherCreateRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The `CipherRequestModel` created from the cipher containing the details of the cipher.
    let cipher: CipherRequestModel

    /// A list of collection IDs to add the cipher to.
    let collectionIds: [String]
}

extension CipherCreateRequestModel {
    /// Initialize a `CipherCreateRequestModel` from a `Cipher`.
    ///
    /// - Parameters:
    ///   - cipher: The `Cipher` used to initialize a `CipherCreateRequestModel`.
    ///   - encryptedByKeyId: The hex-encoded ID of the key used to encrypt the `cipher`.
    ///   - encryptedFor: The user ID who encrypted the `cipher`.
    init(cipher: Cipher, encryptedByKeyId: String? = nil, encryptedFor: String?) {
        self.cipher = CipherRequestModel(cipher: cipher, encryptedByKeyId: encryptedByKeyId, encryptedFor: encryptedFor)
        collectionIds = cipher.collectionIds
    }
}
