import SwiftUI

@testable import BitwardenShared

extension ProfileSwitcherItem {
    static let anneAccount = ProfileSwitcherItem.fixture(
        color: .purple,
        email: "anne.account@bitwarden.com",
        userInitials: "AA"
    )
}

extension ProfileSwitcherItem {
    static func fixture(
        color: Color = .purple,
        email: String = "",
        isUnlocked: Bool = false,
        userId: String = UUID().uuidString,
        userInitials: String = ".."
    ) -> ProfileSwitcherItem {
        ProfileSwitcherItem(
            color: color,
            email: email,
            isUnlocked: isUnlocked,
            userId: userId,
            userInitials: userInitials
        )
    }
}

extension ProfileSwitcherState {
    static let subMaximumAccounts = ProfileSwitcherState(
        accounts: [
            .anneAccount,
            .fixture(
                color: .yellow,
                email: "bonus.bridge@bitwarden.com",
                isUnlocked: true,
                userInitials: "BB"
            ),
            .fixture(
                color: .teal,
                email: "concurrent.claim@bitarden.com",
                isUnlocked: true,
                userInitials: "CC"
            ),
            .fixture(
                color: .indigo,
                email: "double.dip@bitwarde.com",
                isUnlocked: true,
                userInitials: "DD"
            ),
        ],
        activeAccountId: ProfileSwitcherItem.anneAccount.userId,
        allowLockAndLogout: true,
        isVisible: true
    )

    static let maximumAccounts = ProfileSwitcherState(
        accounts: [
            .anneAccount,
            .fixture(
                color: .yellow,
                email: "bonus.bridge@bitwarden.com",
                isUnlocked: true,
                userInitials: "BB"
            ),
            .fixture(
                color: .teal,
                email: "concurrent.claim@bitarden.com",
                isUnlocked: true,
                userInitials: "CC"
            ),
            .fixture(
                color: .indigo,
                email: "double.dip@bitwarde.com",
                isUnlocked: true,
                userInitials: "DD"
            ),
            .fixture(
                color: .green,
                email: "extra.edition@bitwarden.com",
                isUnlocked: true,
                userInitials: "EE"
            ),
        ],
        activeAccountId: ProfileSwitcherItem.anneAccount.userId,
        allowLockAndLogout: true,
        isVisible: true
    )
}
