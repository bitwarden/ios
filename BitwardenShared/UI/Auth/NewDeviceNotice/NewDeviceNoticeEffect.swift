// MARK: - NewDeviceNoticeEffect

/// Effects that can be processed by a `NewDeviceNoticeProcessor`.
///
enum NewDeviceNoticeEffect: Equatable, Sendable {
    /// The new device notice appeared on screen.
    case appeared

    /// The user tapped the continue button.
    case continueTapped
}
