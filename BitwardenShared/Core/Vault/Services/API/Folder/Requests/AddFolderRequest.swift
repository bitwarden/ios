import Networking

/// Data model for performing an add folder request.
///
struct AddFolderRequest: Request {
    typealias Response = FolderResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: FolderRequestModel? { FolderRequestModel(name: name) }

    /// The HTTP method for this request.
    var method: HTTPMethod { .post }

    /// The URL path for this request.
    var path: String { "/folders" }

    /// The name of the folder to create.
    let name: String
}
