import BitwardenSdk
import Networking

/// Data model for performing a delete cipher request.
///
struct DeleteCipherRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The id of the Cipher
    var id: String

    /// The HTTP method for this request.
    let method = HTTPMethod.delete

    /// The URL path for this request.
    var path: String {
        "/ciphers/" + id
    }

    // MARK: Initialization

    /// Initialize an `DeleteCipherRequest` for a `Cipher`.
    ///
    /// - Parameter id: The id of `Cipher` to be deleted in the user's vault.
    ///
    init(id: String) throws {
        guard !id.isEmpty else { throw CipherAPIServiceError.updateMissingId }
        self.id = id
    }
}
