// MARK: - LoginWithDeviceEffect

/// Effects that can be processed by a `LoginWithDeviceProcessor`.
///
enum LoginWithDeviceEffect: Equatable {
    /// The view appeared.
    case appeared

    /// Resend the login with device notification.
    case resendNotification
}
