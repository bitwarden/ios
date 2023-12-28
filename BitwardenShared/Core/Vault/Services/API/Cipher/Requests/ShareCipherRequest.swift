import BitwardenSdk
import Networking

/// Errors thrown by `ShareCipherRequest`.
///
enum ShareCipherRequestError: Error {
    /// The cipher was missing an ID.
    case missingCipherId
}

/// A request model for sharing a cipher with an organization.
///
struct ShareCipherRequest: Request {
    typealias Response = CipherDetailsResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: CipherCreateRequestModel? {
        requestModel
    }

    /// The cipher's identifier.
    let id: String

    /// The HTTP method for this request.
    let method = HTTPMethod.put

    /// The URL path for this request.
    var path: String { "/ciphers/\(id)/share" }

    /// The request details to include in the body of the request.
    let requestModel: CipherCreateRequestModel

    // MARK: Initialization

    /// Initialize a `ShareCipherRequest` for a `Cipher`.
    ///
    /// - Parameter cipher: The `Cipher` to share with an organization.
    ///
    init(cipher: Cipher) throws {
        guard let id = cipher.id else { throw ShareCipherRequestError.missingCipherId }
        self.id = id
        requestModel = CipherCreateRequestModel(cipher: cipher)
    }
}
