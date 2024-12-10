// MARK: - NewDeviceNoticeAction

/// Actions that can be processed by a `NewDeviceNoticeProcessor`.
///
enum NewDeviceNoticeAction: Equatable, Sendable {
    case canAccessEmailChanged(Bool)

    /// The current page index has changed.
    case currentPageIndexChanged(Int)
}
