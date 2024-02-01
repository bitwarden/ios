import Foundation
import Networking

// MARK: - GetFolderRequest

struct GetFolderRequest: Request {
    typealias Response = FolderResponseModel

    /// The id of the folder to retrieve.
    let folderId: String

    var path: String { "/folders/\(folderId)" }

    let method: HTTPMethod = .get

    /// Creates a new `GetFolderRequest`.
    ///
    /// - Parameter folderId: The id of the folder to retrieve.
    ///
    init(folderId: String) {
        self.folderId = folderId
    }
}
