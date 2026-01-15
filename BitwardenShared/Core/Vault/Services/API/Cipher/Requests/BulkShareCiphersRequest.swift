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

    /// Initialize a `BulkShareCiphersRequest` for multiple `Cipher` objects.
    ///
    /// - Parameters:
    ///   - ciphers: The `Cipher` objects to share with an organization.
    ///   - collectionIds: The collection identifiers to share the ciphers with.
    ///   - encryptedFor: The user ID who encrypted the ciphers.
    ///
    init(ciphers: [Cipher], collectionIds: [String], encryptedFor: String?) throws {
        // Validate all ciphers have IDs
        guard ciphers.allSatisfy({ $0.id != nil }) else {
            throw BulkShareCiphersRequestError.missingCipherId
        }
        requestModel = BulkShareCiphersRequestModel(
            ciphers: ciphers,
            collectionIds: collectionIds,
            encryptedFor: encryptedFor,
        )
    }
}
