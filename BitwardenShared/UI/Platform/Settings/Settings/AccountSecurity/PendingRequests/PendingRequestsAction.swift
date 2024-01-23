// MARK: - PendingRequestsAction

/// Actions that can be processed by a `PendingRequestsProcessor`.
enum PendingRequestsAction: Equatable {
    /// The decline all requests button was tapped.
    case declineAllRequestsTapped

    /// Dismiss the sheet.
    case dismiss

    /// A request was tapped.
    case requestTapped(LoginRequest)

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
