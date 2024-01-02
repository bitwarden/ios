// MARK: - AddEditFolderAction

/// Actions handled by the `AddEditFolderView`.
///
enum AddEditFolderAction: Equatable {
    /// Dismiss the sheet.
    case dismiss

    /// The user edited the folder name text field.
    case folderNameTextChanged(String)
}
