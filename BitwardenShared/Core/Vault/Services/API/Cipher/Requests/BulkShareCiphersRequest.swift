import BitwardenSdk
import Networking

/// Errors thrown by `BulkShareCiphersRequest`.
///
enum BulkShareCiphersRequestError: Error {
    /// One or more ciphers are missing an ID.
    case missingCipherId
}

/// A request model for sharing multiple ciphers with an organization.
///
struct BulkShareCiphersRequest: Request {
    typealias Response = BulkShareCiphersResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: BulkShareCiphersRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method = HTTPMethod.put

    /// The URL path for this request.
    let path = "/ciphers/share"

    /// The request details to include in the body of the request.
    let requestModel: BulkShareCiphersRequestModel

    // MARK: Initialization

    /// Initialize a `BulkShareCiphersRequest` for multiple `EncryptionContext` objects.
    ///
    /// - Parameters:
    ///   - encryptionContexts: The encryption contexts containing the ciphers and per-cipher encryption metadata.
    ///   - collectionIds: The collection identifiers to share the ciphers with.
    ///
    init(encryptionContexts: [EncryptionContext], collectionIds: [String]) throws {
        guard encryptionContexts.allSatisfy({ $0.cipher.id != nil }) else {
            throw BulkShareCiphersRequestError.missingCipherId
        }
        requestModel = BulkShareCiphersRequestModel(
            encryptionContexts: encryptionContexts,
            collectionIds: collectionIds,
        )
    }
}
