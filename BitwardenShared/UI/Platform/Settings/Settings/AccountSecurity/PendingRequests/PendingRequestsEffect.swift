// MARK: - PendingRequestsEffect

/// Effects that can be processed by a `PendingRequestsProcessor`.
enum PendingRequestsEffect: Equatable {
    /// Load the pending login requests.
    case loadData
}
