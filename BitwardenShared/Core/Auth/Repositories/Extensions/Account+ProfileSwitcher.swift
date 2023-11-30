extension Account {
    /// A function to convert an `Account` to a `ProfileSwitcherItem`
    ///
    ///   - Parameter vaultTimeoutService: The vaultTimeoutService to use for lock state.
    ///   - Returns: The `ProfileSwitcherItem` representing the account.
    ///
    func profileItem(vaultTimeoutService: VaultTimeoutService) async -> ProfileSwitcherItem {
        var profile = ProfileSwitcherItem(
            email: profile.email,
            userId: profile.userId,
            userInitials: initials()
                ?? ".."
        )
        do {
            let isUnlocked = try !vaultTimeoutService.isLocked(userId: profile.userId)
            profile.isUnlocked = isUnlocked
            return profile
        } catch {
            profile.isUnlocked = false
            let userId = profile.userId
            await vaultTimeoutService.lockVault(userId: userId)
            return profile
        }
    }
}
