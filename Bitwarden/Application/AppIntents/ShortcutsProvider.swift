import AppIntents

/// The app shortcuts provider.
@available(iOS 16.4, *)
struct ShortcutsProvider: AppShortcutsProvider {
    /// The app shortcuts.
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LockAllAccountsIntent(),
            phrases: [
                "Lock all \(.applicationName) accounts",
                "Secure every \(.applicationName) account",
                "Lock down all \(.applicationName) sessions",
                "\(.applicationName), lock all vaults",
                "Activate full lock for \(.applicationName)",
                "Freeze every \(.applicationName) account",
                "Protect all \(.applicationName) logins",
                "Lock up all accounts in \(.applicationName)",
                "Enable total \(.applicationName) security",
                "\(.applicationName), secure all profiles",
                "Global lock for \(.applicationName)",
            ],
            shortTitle: "LockAllAccounts",
            systemImageName: "lock.circle.dotted",
        )
        AppShortcut(
            intent: LogoutAllAccountsIntent(),
            phrases: [
                "Log out all \(.applicationName) accounts",
                "Sign out of every \(.applicationName) session",
                "\(.applicationName), log out all users",
                "Terminate all \(.applicationName) logins",
                "Disconnect all \(.applicationName) accounts",
                "Remove every \(.applicationName) session",
                "End all \(.applicationName) connections",
                "Close all \(.applicationName) profiles",
                "Full sign-out from \(.applicationName)",
                "Erase all \(.applicationName) sessions",
                "Exit every \(.applicationName) account",
            ],
            shortTitle: "LogOutAllAccounts",
            systemImageName: "person.crop.circle.badge.xmark",
        )
        AppShortcut(
            intent: OpenGeneratorIntent(),
            phrases: [
                "Open password generator using \(.applicationName)",
                "Launch \(.applicationName) password creator",
                "Show the \(.applicationName) generator",
                "Access password maker in \(.applicationName)",
                "\(.applicationName), open generator tool",
                "Go to password generator in \(.applicationName)",
                "Start \(.applicationName) password builder",
                "Open up the \(.applicationName) generator",
                "Load the password creator in \(.applicationName)",
                "Take me to \(.applicationName)'s generator",
                "Begin generating passwords with \(.applicationName)",
            ],
            shortTitle: "OpenPasswordGenerator",
            systemImageName: "arrow.clockwise.square",
        )
        AppShortcut(
            intent: GeneratePassphraseIntent(),
            phrases: [
                "Generate passphrase using \(.applicationName)",
                "Create a \(.applicationName) passphrase",
                "\(.applicationName), make a secure passphrase",
                "Build a new passphrase with \(.applicationName)",
                "Produce a \(.applicationName) password phrase",
                "Generate a random \(.applicationName) phrase",
                "\(.applicationName), craft a passphrase",
                "Design a secure passphrase via \(.applicationName)",
                "Develop a \(.applicationName) secret phrase",
                "Compose a new \(.applicationName) passphrase",
                "\(.applicationName), generate a strong passphrase",
            ],
            shortTitle: "GeneratePassphrase",
            systemImageName: "arrow.clockwise",
        )
    }
}
