// MARK: - ProfileSwitcherRowState

/// State defining a Profile Switcher Row
struct ProfileSwitcherRowState: Equatable {
    /// The possible row types
    enum RowType: Equatable {
        /// Add Account
        ///
        case addAccount
        /// Active Account
        /// - Parameters
        ///   - `ProfileSwitcherItem`: The profile
        ///   - `showDivider`: a flag for toggling divider visibility, defaults to true
        ///
        case active(ProfileSwitcherItem)
        /// AlternateAccount
        /// - Parameter `ProfileSwitcherItem`
        ///
        case alternate(ProfileSwitcherItem)
    }

    /// Should the row allow lock and logout?
    var allowLockAndLogout: Bool = true

    /// A flag for tracking accessibility focus
    var shouldTakeAccessibilityFocus: Bool

    /// A flag for row divider visibility
    var showDivider: Bool = true

    /// The type of the row
    var rowType: RowType
}
