import Foundation

/// API response model for a folder.
///
struct FolderResponseModel: Codable, Equatable {
    // MARK: Properties

    /// The folder's identifier.
    let id: String?

    /// The folder's name.
    let name: String?

    /// The response object type.
    let object: String?

    /// The date of the folder's last revision.
    let revisionDate: Date
}
