import BitwardenSdk
import Networking

/// A request model for updating a cipher's preference.
///
struct UpdateCipherPreferenceRequest: Request {
    typealias Response = CipherDetailsResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: UpdateCipherPreferenceRequestModel? {
        requestModel
    }

    /// The id of the Cipher
    var id: String

    /// The HTTP method for this request.
    let method = HTTPMethod.put

    /// The URL path for this request.
    var path: String {
        "/ciphers/" + id + "/partial"
    }

    /// The request details to include in the body of the request.
    let requestModel: UpdateCipherPreferenceRequestModel

    // MARK: Initialization

    /// Initializes a new instance of the request.
    ///
    /// - Parameter cipher: The `Cipher` to update in the user's vault.
    ///
    init(cipher: Cipher) throws {
        guard let id = cipher.id,
              !id.isEmpty else { throw CipherAPIServiceError.updateMissingId }
        self.id = id
        requestModel = UpdateCipherPreferenceRequestModel(
            favorite: cipher.favorite,
            folderId: cipher.folderId,
        )
    }
}
