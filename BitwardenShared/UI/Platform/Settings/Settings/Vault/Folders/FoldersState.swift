import BitwardenKit
import BitwardenResources
import BitwardenSdk

// MARK: - FoldersState

/// An object that defines the current state of the `FoldersView`.
///
struct FoldersState: Equatable {
    /// The user's folders.
    var folders: [FolderView] = []

    /// Whether the `vfo1-foundation` feature flag is enabled.
    var isVfo1FoundationFeatureFlagEnabled = false

    /// A toast message to show in the view.
    var toast: Toast?

    // MARK: Computed Properties

    /// The navigation bar title for this screen.
    var navigationTitle: String {
        isVfo1FoundationFeatureFlagEnabled ? Localizations.myFolders : Localizations.folders
    }
}
