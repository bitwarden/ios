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
    /// Initialize a `BulkShareCiphersRequestModel` from an array of `EncryptionContext` objects.
    ///
    /// - Parameters:
    ///   - encryptionContexts: The encryption contexts containing the ciphers and per-cipher encryption metadata.
    ///   - collectionIds: The collection identifiers to share the ciphers with.
    ///
    init(encryptionContexts: [EncryptionContext], collectionIds: [String]) {
        ciphers = encryptionContexts.map { context in
            CipherRequestModel(
                cipher: context.cipher,
                encryptedByKeyId: context.encryptedByKeyId,
                encryptedFor: context.encryptedFor,
                includeId: true,
            )
        }
        self.collectionIds = collectionIds
    }
}
