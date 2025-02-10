import BitwardenSdk

// MARK: - AddEditFolderRoute

/// A route to a specific screen within the add/edit folder flow.
///
enum AddEditFolderRoute: Equatable, Hashable {
    /// A route to add a new folder or edit an existing one.
    ///
    /// - Parameter folder: The existing folder to edit, if applicable.
    ///
    case addEditFolder(folder: FolderView?)

    /// A route that dismisses the current view.
    case dismiss
}
