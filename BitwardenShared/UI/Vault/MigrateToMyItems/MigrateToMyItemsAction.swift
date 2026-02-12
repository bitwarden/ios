// MARK: - MigrateToMyItemsAction

/// Actions that can be processed by a `MigrateToMyItemsProcessor`.
///
enum MigrateToMyItemsAction: Equatable, Sendable {
    /// The user tapped the back button on the decline confirmation screen.
    case backTapped

    /// The user tapped the "Decline and leave" button.
    case declineAndLeaveTapped
}
