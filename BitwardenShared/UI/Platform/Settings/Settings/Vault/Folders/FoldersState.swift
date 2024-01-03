import BitwardenSdk

// MARK: - FoldersState

/// An object that defines the current state of the `FoldersView`.
///
struct FoldersState: Equatable {
    /// The user's folders.
    var folders: [FolderView] = []

    /// A toast message to show in the view.
    var toast: Toast?
}
