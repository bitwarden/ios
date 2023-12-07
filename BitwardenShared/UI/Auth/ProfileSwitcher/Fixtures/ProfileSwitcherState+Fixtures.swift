@testable import BitwardenShared

extension ProfileSwitcherItem {
    static let anneAccount = ProfileSwitcherItem(
        color: .purple,
        email: "anne.account@bitwarden.com",
        userInitials: "AA"
    )
}

extension ProfileSwitcherState {
    static let subMaximumAccounts = ProfileSwitcherState(
        accounts: [
            .anneAccount,
            ProfileSwitcherItem(
                color: .yellow,
                email: "bonus.bridge@bitwarden.com",
                isUnlocked: true,
                userInitials: "BB"
            ),
            ProfileSwitcherItem(
                color: .teal,
                email: "concurrent.claim@bitarden.com",
                isUnlocked: true,
                userInitials: "CC"
            ),
            ProfileSwitcherItem(
                color: .indigo,
                email: "double.dip@bitwarde.com",
                isUnlocked: true,
                userInitials: "DD"
            ),
        ],
        activeAccountId: ProfileSwitcherItem.anneAccount.userId,
        isVisible: true
    )

    static let maximumAccounts = ProfileSwitcherState(
        accounts: [
            .anneAccount,
            ProfileSwitcherItem(
                color: .yellow,
                email: "bonus.bridge@bitwarden.com",
                isUnlocked: true,
                userInitials: "BB"
            ),
            ProfileSwitcherItem(
                color: .teal,
                email: "concurrent.claim@bitarden.com",
                isUnlocked: true,
                userInitials: "CC"
            ),
            ProfileSwitcherItem(
                color: .indigo,
                email: "double.dip@bitwarde.com",
                isUnlocked: true,
                userInitials: "DD"
            ),
            ProfileSwitcherItem(
                color: .green,
                email: "extra.edition@bitwarden.com",
                isUnlocked: true,
                userInitials: "EE"
            ),
        ],
        activeAccountId: ProfileSwitcherItem.anneAccount.userId,
        isVisible: true
    )
}
