import BitwardenSdk
import Networking

/// Data model for performing an unarchive cipher request.
///
struct UnarchiveCipherRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The id of the Cipher
    var id: String

    /// The HTTP method for this request.
    let method = HTTPMethod.put

    /// The URL path for this request.
    var path: String {
        "/ciphers/\(id)/unarchive/"
    }

    // MARK: Initialization

    /// Initialize a `UnarchiveCipherRequest` for a `Cipher`.
    ///
    /// - Parameter id: The id of the `Cipher` to be unarchived from the vault.
    ///
    init(id: String) throws {
        guard !id.isEmpty else { throw CipherAPIServiceError.updateMissingId }
        self.id = id
    }
}
