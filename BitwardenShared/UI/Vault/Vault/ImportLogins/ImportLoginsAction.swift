// MARK: - ImportLoginsAction

/// Actions that can be processed by a `ImportLoginsProcessor`.
///
enum ImportLoginsAction: Equatable {
    /// Advance to the next page of instructions.
    case advanceNextPage

    /// Advance to the previous page of instructions.
    case advancePreviousPage

    /// Dismiss the view.
    case dismiss

    /// The get started button was tapped.
    case getStarted
}
