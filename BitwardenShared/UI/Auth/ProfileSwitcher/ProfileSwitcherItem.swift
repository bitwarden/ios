import BitwardenResources
import SwiftUI

// MARK: - ProfileSwitcherItem

/// An object that defines account profile information relevant to account switching
/// Part of `ProfileSwitcherState`.
struct ProfileSwitcherItem: Equatable, Hashable {
    /// Indicates if the account can be locked.
    var canBeLocked: Bool

    /// The color associated with the profile
    var color: Color = SharedAsset.Colors.backgroundTertiary.swiftUIColor

    /// The account's email.
    var email: String

    /// Whether the account is soft logged out.
    var isLoggedOut: Bool

    /// The the locked state of an account profile.
    var isUnlocked: Bool

    /// The color to use for the profile icon text.
    var profileIconTextColor: Color {
        color.isLight() ? .black : .white
    }

    /// The user's identifier
    var userId: String

    /// The user's initials.
    var userInitials: String?

    /// The account's email.
    var webVault: String
}
