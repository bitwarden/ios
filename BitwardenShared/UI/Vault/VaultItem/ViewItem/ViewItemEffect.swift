// MARK: - ViewItemEffect

/// Effects that can be processed by a `ViewItemProcessor`.
enum ViewItemEffect: Equatable {
    /// The view item screen appeared.
    case appeared

    /// The delete option was pressed.
    case deletePressed

    /// The edit button was pressed.
    case editPressed

    /// A flag indicating if this action requires the user to re-enter their master password to
    /// complete. This value works hand-in-hand with the `isMasterPasswordRequired` value in
    /// `ViewItemState`.
    var requiresMasterPasswordReprompt: Bool {
        switch self {
        case .editPressed:
            true
        case .appeared,
             .deletePressed:
            false
        }
    }
}
