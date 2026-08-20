import BitwardenSdk
import Networking

/// API request model for bulk sharing ciphers with an organization.
///
struct BulkShareCiphersRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The ciphers to share with the organization.
    let ciphers: [CipherRequestModel]

    /// The collection identifiers to share the ciphers with.
    let collectionIds: [String]
}

extension BulkShareCiphersRequestModel {
    /// Initialize a `BulkShareCiphersRequestModel` from an array of `Cipher` objects.
    ///
    /// - Parameters:
    ///   - ciphers: The `Cipher` objects to share.
    ///   - collectionIds: The collection identifiers to share the ciphers with.
    ///   - encryptedByKeyId: The hex-encoded ID of the key used to encrypt the ciphers.
    ///   - encryptedFor: The user ID who encrypted the ciphers.
    ///
    init(ciphers: [Cipher], collectionIds: [String], encryptedByKeyId: String? = nil, encryptedFor: String?) {
        self.ciphers = ciphers.map { cipher in
            CipherRequestModel(
                cipher: cipher,
                encryptedByKeyId: encryptedByKeyId,
                encryptedFor: encryptedFor,
                includeId: true,
            )
        }
        self.collectionIds = collectionIds
    }
}
