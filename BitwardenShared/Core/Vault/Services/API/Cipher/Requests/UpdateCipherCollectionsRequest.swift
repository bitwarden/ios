import BitwardenSdk
import Networking

/// Errors thrown by `UpdateCipherCollectionsRequest`.
///
enum UpdateCipherCollectionsRequestError: Error {
    /// The cipher was missing an ID.
    case missingCipherId
}

/// A request model for sharing a cipher with an organization.
///
struct UpdateCipherCollectionsRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of the request.
    var body: CipherCollectionsRequestModel? {
        requestModel
    }

    /// The cipher's identifier.
    let id: String

    /// The HTTP method for this request.
    let method = HTTPMethod.put

    /// The URL path for this request.
    var path: String { "/ciphers/\(id)/collections" }

    /// The request details to include in the body of the request.
    let requestModel: CipherCollectionsRequestModel

    // MARK: Initialization

    /// Initialize a `ShareCipherRequest` for a `Cipher`.
    ///
    /// - Parameter cipher: The `Cipher` to share with an organization.
    ///
    init(cipher: Cipher) throws {
        guard let id = cipher.id else { throw UpdateCipherCollectionsRequestError.missingCipherId }
        self.id = id
        requestModel = CipherCollectionsRequestModel(collectionIds: cipher.collectionIds)
    }
}
