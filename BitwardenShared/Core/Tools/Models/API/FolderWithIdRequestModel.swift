import BitwardenSdk

/// API model for a request of a folder with id.
///
struct FolderWithIdRequestModel: Codable, Equatable {
    // MARK: Properties

    /// A identifier for the folder.
    let id: String?

    /// The name of the folder.
    let name: String?

    /// Inits a `FolderWithIdRequestModel` from a `Folder`
    /// - Parameter folder: Folder from which initialize this request model.
    init(folder: Folder) {
        id = folder.id
        name = folder.name
    }
}
