import BitwardenSdk
import Networking

/// Data model for performing an archive cipher request.
///
struct ArchiveCipherRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The id of the Cipher
    var id: String

    /// The HTTP method for this request.
    let method = HTTPMethod.put

    /// The URL path for this request.
    var path: String {
        "/ciphers/\(id)/archive/"
    }

    // MARK: Initialization

    /// Initialize an `ArchiveCipherRequest` for a `Cipher`.
    ///
    /// - Parameter id: The id of `Cipher` to be archived in the user's vault.
    ///
    init(id: String) throws {
        guard !id.isEmpty else { throw CipherAPIServiceError.updateMissingId }
        self.id = id
    }
}
