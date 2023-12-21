import Foundation
import Networking

/// API response model for a folder.
///
struct FolderResponseModel: JSONResponse, Codable, Equatable, Hashable {
    // MARK: Properties

    /// The folder's identifier.
    let id: String

    /// The folder's name.
    let name: String

    /// The date of the folder's last revision.
    let revisionDate: Date
}
