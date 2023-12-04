// MARK: - ViewItemEffect

/// Effects that can be processed by a `ViewItemProcessor`.
enum ViewItemEffect: Equatable {
    /// The view item screen appeared.
    case appeared

    /// The check password button was pressed.
    case checkPasswordPressed

    /// The setup totp button was pressed.
    case setupTotpPressed
}
