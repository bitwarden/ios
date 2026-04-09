// MARK: - MigrateToMyItemsEffect

/// Effects that can be processed by a `MigrateToMyItemsProcessor`.
///
enum MigrateToMyItemsEffect: Equatable, Sendable {
    /// The user tapped the "Accept transfer" button.
    case acceptTransferTapped

    /// The view appeared on screen.
    case appeared

    /// The user tapped the "Leave {organization}" button to confirm leaving.
    case leaveOrganizationTapped
}
