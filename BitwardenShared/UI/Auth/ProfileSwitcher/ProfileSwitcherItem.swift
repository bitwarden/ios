import SwiftUI

// MARK: - ProfileSwitcherItem

/// An object that defines account profile information relevant to account switching
/// Part of `ProfileSwitcherState`.
struct ProfileSwitcherItem: Equatable, Hashable {
    /// A placeholder empty item.
    static var empty: ProfileSwitcherItem {
        ProfileSwitcherItem(
            email: "",
            isUnlocked: false,
            userId: "",
            userInitials: "..",
            webVault: ""
        )
    }

    /// The color associated with the profile
    var color = Color.purple

    /// The account's email.
    var email: String

    /// The the locked state of an account profile
    var isUnlocked: Bool

    /// The user's identifier
    var userId: String

    /// The user's initials.
    var userInitials: String

    /// The account's email.
    var webVault: String
}
