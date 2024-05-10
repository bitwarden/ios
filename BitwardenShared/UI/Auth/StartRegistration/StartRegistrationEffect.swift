// MARK: - StartRegistrationEffect

/// The enumeration of possible effects performed by the `StartRegistrationProcessor`.
///
enum StartRegistrationEffect: Equatable {
    /// The vault list appeared on screen.
    case appeared

    /// The user pressed `Submit` on the `StartRegistrationView`, attempting to create an account.
    case startRegistration
}
