// MARK: - FoldersAction

/// Actions handled by the `FoldersProcessor`.
///
enum FoldersAction: Equatable {
    /// The button to add a new folder was tapped.
    case add

    /// A folder was tapped.
    case folderTapped(id: String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
