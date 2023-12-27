// MARK: - SingleSignOnAction

/// Actions handled by the `SingleSignOnProcessor`.
///
enum SingleSignOnAction: Equatable {
    /// Dismiss the view.
    case dismiss

    /// The text was changed.
    case identifierTextChanged(String)
}
