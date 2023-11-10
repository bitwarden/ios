import BitwardenSdk

/// Actions that can be processed by a `GeneratorHistoryProcessor`.
///
enum GeneratorHistoryAction: Equatable {
    /// The copy password button was tapped for a password.
    case copyPassword(PasswordHistoryView)

    /// The close button was tapped to dismiss the view.
    case dismiss
}
