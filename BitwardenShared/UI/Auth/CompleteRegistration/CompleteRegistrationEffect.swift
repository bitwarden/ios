// MARK: - CompleteRegistrationEffect

/// The enumeration of possible effects performed by the `CompleteRegistrationProcessor`.
///
enum CompleteRegistrationEffect: Equatable {
    /// The complete registration modal appeared on screen.
    case appeared

    /// The user pressed `Submit` on the `CompleteRegistrationView`, attempting to create an account.
    case completeRegistration

    /// The user pressed the button to create an account without a master password. The account
    /// is protected by a device auth key.
    case completeRegistrationWithDeviceAuthKey
}
