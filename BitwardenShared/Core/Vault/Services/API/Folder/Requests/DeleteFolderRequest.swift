import Networking

/// Data model for performing a delete folder request.
///
struct DeleteFolderRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The ID of the folder to edit.
    let id: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .delete }

    /// The URL path for this request.
    var path: String { "/folders/\(id)" }
}
