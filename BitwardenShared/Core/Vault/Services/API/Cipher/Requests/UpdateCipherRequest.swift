import BitwardenSdk
import Networking

/// A request model for updating a cipher.
///
struct UpdateCipherRequest: Request {
    typealias Response = CipherDetailsResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: CipherRequestModel? {
        requestModel
    }

    /// The id of the Cipher
    var id: String

    /// The HTTP method for this request.
    let method = HTTPMethod.put

    /// The URL path for this request.
    var path: String {
        "/ciphers/" + id
    }

    /// The request details to include in the body of the request.
    let requestModel: CipherRequestModel

    // MARK: Initialization

    /// Initialize an `UpdateCipherRequest` for a `Cipher`.
    ///
    /// - Parameters:
    ///   - cipher: The `Cipher` to update in the user's vault.
    ///   - encryptedFor: The user ID who encrypted the `cipher`.
    init(cipher: Cipher, encryptedFor: String?) throws {
        guard let id = cipher.id,
              !id.isEmpty else { throw CipherAPIServiceError.updateMissingId }
        self.id = id
        requestModel = CipherRequestModel(cipher: cipher, encryptedFor: encryptedFor)
    }
}
