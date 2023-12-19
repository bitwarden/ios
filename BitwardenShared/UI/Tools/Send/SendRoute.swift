// MARK: SendRoute

/// The route to a specific screen in the send tab.
///
public enum SendRoute: Equatable {
    /// A route to the add item screen.
    case addItem

    /// A route that dismisses a presented sheet.
    case dismiss

    /// A route to the send screen.
    case list
}
