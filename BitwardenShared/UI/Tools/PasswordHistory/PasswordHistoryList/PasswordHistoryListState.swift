@preconcurrency import BitwardenSdk
import Foundation

// MARK: - PasswordHistoryList

/// An object that defines the current state of a `PasswordHistoryListView`.
///
struct PasswordHistoryListState: Equatable, Sendable {
    // MARK: Types

    /// The source of the password history.
    enum Source: Equatable, Hashable {
        /// Display password history from the generator.
        case generator

        /// Display password history for an item.
        case item(_ passwordHistory: [PasswordHistoryView])
    }

    // MARK: Properties

    /// The password history to display.
    var passwordHistory = [PasswordHistoryView]()

    /// The source of the password history.
    var source: Source = .generator

    /// A toast message to show in the view.
    var toast: Toast?
}
