/// The locked status of the active user account.
///
struct VaultLockStatus: Equatable {
    // MARK: Properties

    /// Whether the user's vault is locked.
    let isVaultLocked: Bool

    /// The ID of the active user.
    let userId: String
}
