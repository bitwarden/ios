// MARK: - PendingRequestsState

/// The state used to present the `PendingRequestsView`.
struct PendingRequestsState: Equatable {
    /// The loading state of the pending requests screen.
    var loadingState: LoadingState<[LoginRequest]> = .loading(nil)

    /// A toast message to show in the view.
    var toast: Toast?
}
