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
    /// - Parameter cipher: The `Cipher` used to initialize a `CipherCreateRequestModel`.
    ///
    init(cipher: Cipher) {
        self.cipher = CipherRequestModel(cipher: cipher)
        collectionIds = cipher.collectionIds
    }
}
