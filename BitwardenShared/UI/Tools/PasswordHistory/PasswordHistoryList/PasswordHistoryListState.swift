import BitwardenSdk
import Foundation

// MARK: - PasswordHistoryList

/// An object that defines the current state of a `PasswordHistoryListView`.
///
struct PasswordHistoryListState: Equatable {
    // MARK: Properties

    /// The user's history of generated passwords.
    var passwordHistory = [PasswordHistoryView]()

    /// Whether to show the button to clear the history.
    var showClearButton = true

    /// A toast message to show in the view.
    var toast: Toast?
}
