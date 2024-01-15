// MARK: - ViewItemEffect

/// Effects that can be processed by a `ViewItemProcessor`.
enum ViewItemEffect: Equatable {
    /// The view item screen appeared.
    case appeared

    /// The delete option was pressed.
    case deletePressed

    /// The TOTP code for the view expired.
    case totpCodeExpired
}
