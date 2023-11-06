import SwiftUI

// MARK: - ProfileSwitcherItem

/// An object that defines account profile information relevant to account switching
/// Part of `ProfileSwitcherState`.
struct ProfileSwitcherItem: Equatable {
    /// The color associated with the profile
    var color = Color.purple

    /// The account's email.
    var email = ""

    /// The the locked state of an account profile
    var isUnlocked = true

    /// The user's identifier
    var userId = UUID().uuidString

    /// The user's initials.
    var userInitials = ""
}
