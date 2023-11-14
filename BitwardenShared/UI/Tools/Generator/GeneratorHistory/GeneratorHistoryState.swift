import BitwardenSdk
import Foundation

/// An object that defines the current state of a `GeneratorHistoryView`.
///
struct GeneratorHistoryState: Equatable {
    // MARK: Properties

    /// The user's history of generated passwords.
    var passwordHistory: [PasswordHistoryView] = []
}
