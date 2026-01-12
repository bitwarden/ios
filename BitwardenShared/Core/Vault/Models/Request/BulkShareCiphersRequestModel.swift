import BitwardenSdk
import Networking

/// API request model for bulk sharing ciphers with an organization.
///
struct BulkShareCiphersRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The ciphers to share with the organization.
    let ciphers: [CipherCreateRequestModel]

    /// The collection identifiers to share the ciphers with.
    let collectionIds: [String]
}

extension BulkShareCiphersRequestModel {
    /// Initialize a `BulkShareCiphersRequestModel` from an array of `Cipher` objects.
    ///
    /// - Parameters:
    ///   - ciphers: The `Cipher` objects to share.
    ///   - collectionIds: The collection identifiers to share the ciphers with.
    ///   - encryptedFor: The user ID who encrypted the ciphers.
    ///
    init(ciphers: [Cipher], collectionIds: [String], encryptedFor: String?) {
        self.ciphers = ciphers.map { CipherCreateRequestModel(cipher: $0, encryptedFor: encryptedFor) }
        self.collectionIds = collectionIds
    }
}
