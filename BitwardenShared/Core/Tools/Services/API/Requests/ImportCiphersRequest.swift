import BitwardenSdk
import Networking

/// A request model for importing ciphers.
///
struct ImportCiphersRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of the request.
    var body: ImportCiphersRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method = HTTPMethod.post

    /// The URL path for this request.
    let path = "/ciphers/import"

    /// The request details to include in the body of the request.
    let requestModel: ImportCiphersRequestModel

    // MARK: Initialization

    /// Initialize a `ImportCiphersRequest` for ciphers, folders and its relattionship.
    /// - Parameters:
    ///   - ciphers: Ciphers to import.
    ///   - folders: Folders to import.
    ///   - folderRelationships: The cipher<->folder relationships map. The key is the cipher index
    ///   and the value is the folder index in their respective arrays.
    init(
        ciphers: [Cipher],
        folders: [Folder] = [],
        folderRelationships: [(key: Int, value: Int)] = [],
    ) throws {
        guard !ciphers.isEmpty else {
            throw BitwardenError.dataError("There are no ciphers to import.")
        }

        requestModel = ImportCiphersRequestModel(
            ciphers: ciphers.map { CipherRequestModel(cipher: $0) },
            folders: folders.map { FolderWithIdRequestModel(folder: $0) },
            folderRelationships: folderRelationships.map { FolderRelationship(key: $0.key, value: $0.value) },
        )
    }
}
