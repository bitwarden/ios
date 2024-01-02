import BitwardenSdk
import Networking

/// A request model for adding a new cipher.
///
struct AddCipherRequest: Request {
    typealias Response = CipherDetailsResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: CipherRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method = HTTPMethod.post

    /// The URL path for this request.
    let path = "/ciphers"

    /// The request details to include in the body of the request.
    let requestModel: CipherRequestModel

    // MARK: Initialization

    /// Initialize an `AddCipherRequest` for a `Cipher`.
    ///
    /// - Parameter cipher: The `Cipher` to add to the user's vault.
    ///
    init(cipher: Cipher) {
        requestModel = CipherRequestModel(cipher: cipher)
    }
}
