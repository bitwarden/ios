@preconcurrency import BitwardenSdk

// MARK: - PasswordHistoryListAction

/// Actions that can be processed by a `PasswordHistoryListProcessor`.
///
enum PasswordHistoryListAction: Equatable, Sendable {
    /// The copy password button was tapped for a password.
    case copyPassword(PasswordHistoryView)

    /// The close button was tapped to dismiss the view.
    case dismiss

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
