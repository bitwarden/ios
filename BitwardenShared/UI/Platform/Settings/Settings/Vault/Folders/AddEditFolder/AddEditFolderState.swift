import BitwardenSdk

// MARK: - AddEditFolderState

/// An object that defines the current state of the`AddEditFolderView`.
///
struct AddEditFolderState: Equatable {
    // MARK: Types

    /// The modes possible for the view.
    enum Mode: Equatable {
        /// Adding a new folder.
        case add

        /// Editing an existing folder.
        case edit(FolderView)
    }

    // MARK: Properties

    /// The new name of the folder.
    var folderName = ""

    /// Whether the view is in the add or edit folder mode.
    var mode: Mode
}
