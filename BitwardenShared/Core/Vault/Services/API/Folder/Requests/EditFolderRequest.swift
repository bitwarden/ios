import BitwardenSdk
import Networking

/// Data model for performing an edit folder request.
///
struct EditFolderRequest: Request {
    typealias Response = FolderResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: FolderRequestModel? { FolderRequestModel(name: name) }

    /// The ID of the folder to edit.
    let id: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .put }

    /// The URL path for this request.
    let path: String

    /// The new name of the folder.
    let name: String

    // MARK: Initialization

    init(id: String, name: String) {
        self.id = id
        self.name = name
        path = "/folders/\(id)"
    }
}
