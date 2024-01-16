import BitwardenSdk

// MARK: - PasswordHistoryRoute

/// A route to specific screens in the password history view.
enum PasswordHistoryRoute: Equatable, Hashable {
    /// Dismiss the view.
    case dismiss

    /// Show the password history list.
    ///
    /// - Parameter source: The source of the password history.
    ///
    case passwordHistoryList(_ source: PasswordHistoryListState.Source)
}
