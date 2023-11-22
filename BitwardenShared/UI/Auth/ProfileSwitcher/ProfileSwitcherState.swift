import SwiftUI

// MARK: - ProfileSwitcherState

/// An object that defines the current state of profile selection.
///
struct ProfileSwitcherState: Equatable {
    // MARK: Static Properties

    // MARK: Properties

    /// All accounts/profiles.
    var accounts: [ProfileSwitcherItem]

    /// The user id of the active account.
    var activeAccountId: String?

    /// The account profile currently in use.
    var activeAccountProfile: ProfileSwitcherItem? {
        accounts.first(where: { $0.userId == activeAccountId })
    }

    /// The user id of the active account.
    var activeAccountInitials: String {
        activeAccountProfile?.userInitials ?? ".."
    }

    /// A list of alternate accounts/profiles.
    var alternateAccounts: [ProfileSwitcherItem] {
        accounts.filter { $0.userId != activeAccountId }
    }

    /// A flag for tracking accessibility focus.
    var hasSetAccessibilityFocus: Bool = false

    /// A flag for view visibility.
    var isVisible: Bool

    /// The observed offset of the scrollView.
    var scrollOffset: CGPoint

    /// A flag to indicate if an add account row should be visible.
    private let shouldAlwaysHideAddAccount: Bool

    /// The visibility of the add account row.
    var showsAddAccount: Bool {
        !shouldAlwaysHideAddAccount && accounts.count < Constants.maxAcccounts
    }

    // MARK: Initialization

    /// Initialize the `ProfileSwitcherState`
    ///
    /// - Parameters:
    ///   - alternateAccounts: A list of alternate `ProfileSwitcherItem` profiles
    ///   - currentAccountProfile: The current `ProfileSwitcherItem` profile
    ///   - isVisible: The visibility of the view
    ///   - scrollOffset: The offset of the scroll view
    ///   - shouldAlwaysHideAddAccount: Overrides visibility of the add account row
    ///
    init(
        accounts: [ProfileSwitcherItem],
        activeAccountId: String?,
        isVisible: Bool,
        scrollOffset: CGPoint = .zero,
        shouldAlwaysHideAddAccount: Bool = false
    ) {
        self.accounts = accounts
        self.activeAccountId = activeAccountId
        self.isVisible = isVisible
        self.scrollOffset = scrollOffset
        self.shouldAlwaysHideAddAccount = shouldAlwaysHideAddAccount
    }

    /// Determines if a row type should take accessibility focus.
    /// - Parameter rowType: The row type.
    /// - Returns: A boolean
    ///
    func shouldSetAccessibilityFocus(for rowType: ProfileSwitcherRowState.RowType) -> Bool {
        guard case .active = rowType else {
            return false
        }

        return isVisible && !hasSetAccessibilityFocus
    }
}
