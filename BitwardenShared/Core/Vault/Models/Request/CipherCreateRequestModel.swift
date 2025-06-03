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
    ///   - encryptedFor: The user ID who encrypted the `cipher`.
    init(cipher: Cipher, encryptedFor: String?) {
        self.cipher = CipherRequestModel(cipher: cipher, encryptedFor: encryptedFor)
        collectionIds = cipher.collectionIds
    }
}
