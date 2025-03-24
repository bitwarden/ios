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
    /// - Parameters:
    ///   - cipherId: The id of the cipher to update.
    ///   - folderId: The id of the folder to move the cipher to.
    ///   - isFavorite: The new favorite status of the cipher.
    ///
    init(cipherId: String, folderId: String?, isFavorite: Bool) {
        id = cipherId
        requestModel = UpdateCipherPreferenceRequestModel(
            folderId: folderId,
            favorite: isFavorite
        )
    }
}
