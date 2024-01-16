import BitwardenSdk
import Networking

/// Data model for performing a restore cipher request.
///
struct RestoreCipherRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The id of the Cipher
    var id: String

    /// The HTTP method for this request.
    let method = HTTPMethod.put

    /// The URL path for this request.
    var path: String {
        "/ciphers/" + id + "/restore"
    }

    // MARK: Initialization

    /// Initialize an `RestoreCipherRequest` for a `Cipher`.
    ///
    /// - Parameter id: The id of `Cipher` to be restored from the trash.
    ///
    init(id: String) throws {
        guard !id.isEmpty else { throw CipherAPIServiceError.updateMissingId }
        self.id = id
    }
}
