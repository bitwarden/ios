import AppIntents

/// The app shortcuts provider.
@available(iOS 16.0, *)
struct ShortcutsProvider: AppShortcutsProvider {
    /// The app shortcuts.
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LockAllAccountsIntent(),
            phrases: [
                "Lock all \(.applicationName) accounts",
            ],
            shortTitle: "LockAllAccounts",
            systemImageName: "lock.circle.dotted"
        )
    }
}
