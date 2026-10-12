import BitwardenSdk
import Networking

/// A request model for adding a new cipher within one or more collections.
///
struct AddCipherWithCollectionsRequest: Request {
    typealias Response = CipherDetailsResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: CipherCreateRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method = HTTPMethod.post

    /// The URL path for this request.
    let path = "/ciphers/create"

    /// The request details to include in the body of the request.
    let requestModel: CipherCreateRequestModel

    // MARK: Initialization

    /// Initialize an `AddCipherWithCollectionsRequest` for a `Cipher`.
    ///
    /// - Parameters:
    ///   - cipher: The `Cipher` to add to the user's vault.
    ///   - encryptedByKeyId: The hex-encoded ID of the key used to encrypt the `cipher`.
    ///   - encryptedFor: The user ID who encrypted the `cipher`.
    init(cipher: Cipher, encryptedByKeyId: String? = nil, encryptedFor: String?) {
        requestModel = CipherCreateRequestModel(
            cipher: cipher,
            encryptedByKeyId: encryptedByKeyId,
            encryptedFor: encryptedFor,
        )
    }
}
