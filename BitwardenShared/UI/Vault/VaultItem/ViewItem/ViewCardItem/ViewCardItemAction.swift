// MARK: ViewCardItemAction

/// An enum of actions for adding or editing a card Item in its view state.
///
enum ViewCardItemAction: Equatable {
    /// Toggle for code visibility changed.
    case toggleCodeVisibilityChanged(Bool)

    /// Toggle for number visibility changed.
    case toggleNumberVisibilityChanged(Bool)
}
