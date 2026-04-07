import Foundation

// MARK: - FolderSelectionDelegate

/// A delegate object that responds to folder selection events.
///
@MainActor
protocol FolderSelectionDelegate: AnyObject {
    /// A folder was chosen by the user.
    ///
    /// - Parameter folderURL: The URL of the selected folder.
    ///
    func folderSelectionCompleted(folderURL: URL)
}
