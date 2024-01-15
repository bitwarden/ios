import BitwardenSdk

// MARK: - PasswordHistoryRoute

/// A route to specific screens in the password history view.
enum PasswordHistoryRoute: Equatable, Hashable {
    /// Dismiss the view.
    case dismiss

    /// Show the password history list.
    ///
    /// - Parameter passwordHistory: The password history to display, if already known.
    ///
    case passwordHistoryList(_ passwordHistory: [PasswordHistoryView]?)
}
