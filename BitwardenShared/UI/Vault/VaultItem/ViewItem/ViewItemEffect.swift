// MARK: - ViewItemEffect

/// Effects that can be processed by a `ViewItemProcessor`.
enum ViewItemEffect: Equatable {
    /// The archived button was pressed.
    case archivedPressed

    /// The view item screen appeared.
    case appeared

    /// The check password button was pressed.
    case checkPasswordPressed

    /// The delete option was pressed.
    case deletePressed

    /// Toggles displaying one or multiple collections.
    case toggleDisplayMultipleCollections

    /// The TOTP code for the view expired.
    case totpCodeExpired

    /// The unarchive button was pressed.
    case unarchivePressed
}
