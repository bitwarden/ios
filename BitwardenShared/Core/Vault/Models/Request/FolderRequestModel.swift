import Networking

/// API request model for adding or updating a folder.
///
struct FolderRequestModel: JSONRequestBody, Equatable {
    // MARK: Properties

    /// The name of the folder.
    let name: String?
}
