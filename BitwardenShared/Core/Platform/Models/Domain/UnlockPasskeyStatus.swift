/// An object that defines the current state of the unlock passkey for an account.
///
struct UnlockOtherDevicesStatus: Equatable {
    // MARK: Properties

    /// Whether the unlock with other devices setting is enabled for the user.
    let isUnlockOtherDevicesEnabled: Bool

    /// The associated user account.
    let userId: String
}
