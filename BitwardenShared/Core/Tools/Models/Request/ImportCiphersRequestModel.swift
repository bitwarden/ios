import Foundation
import Networking

// MARK: - ImportCiphersRequestModel

/// API request model for importing ciphers.
///
struct ImportCiphersRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The cipher request models to import.
    var ciphers: [CipherRequestModel]

    /// The folders request models to import.
    var folders: [FolderWithIdRequestModel]

    /// The cipher<->folder relationships map. The key is the cipher index and the value is the folder index
    /// in their respective arrays.
    var folderRelationships: [FolderRelationship]
}

/// The cipher<->folder relationships map. The key is the cipher index and the value is the folder index
/// in their respective arrays.
struct FolderRelationship: Codable {
    let key: Int
    let value: Int
}
