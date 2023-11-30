import BitwardenSdk
import Networking

/// Data model for performing a sync request.
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
    /// - Parameter cipher: The `Cipher` to add to the user's vault.
    ///
    init?(cipher: Cipher) {
        guard let id = cipher.id,
              !id.isEmpty else { return nil }
        self.id = id
        requestModel = CipherRequestModel(cipher: cipher)
    }
}
