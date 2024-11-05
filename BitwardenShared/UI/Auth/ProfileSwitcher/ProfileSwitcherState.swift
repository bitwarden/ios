import SwiftUI

// MARK: - ProfileSwitcherState

/// An object that defines the current state of profile selection.
///
struct ProfileSwitcherState: Equatable {
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

    /// Should the view allow lock & logout actions
    var allowLockAndLogout: Bool

    /// A list of alternate accounts/profiles.
    var alternateAccounts: [ProfileSwitcherItem] {
        accounts.filter { $0.userId != activeAccountId }
    }

    /// A flag for tracking accessibility focus.
    var hasSetAccessibilityFocus: Bool = false

    /// A flag for view visibility.
    var isVisible: Bool

    /// A flag to indicate if an add account row should be visible.
    private let shouldAlwaysHideAddAccount: Bool

    /// The visibility of the add account row.
    var showsAddAccount: Bool {
        !shouldAlwaysHideAddAccount && accounts.count < Constants.maxAccounts
    }

    /// Should the handler replace the toolbar icon with two dots?
    let showPlaceholderToolbarIcon: Bool

    // MARK: Initialization

    /// Initialize the `ProfileSwitcherState`.
    ///
    /// - Parameters:
    ///   - alternateAccounts: A list of alternate `ProfileSwitcherItem` profiles.
    ///   - allowLockAndLogout: Should the view be allowed to lock and logout accounts?
    ///   - currentAccountProfile: The current `ProfileSwitcherItem` profile.
    ///   - isVisible: The visibility of the view.
    ///   - shouldAlwaysHideAddAccount: Overrides visibility of the add account row.
    ///   - showPlaceholderToolbarIcon: Should the handler replace the toolbar icon with two dots?
    ///
    init(
        accounts: [ProfileSwitcherItem],
        activeAccountId: String?,
        allowLockAndLogout: Bool,
        isVisible: Bool,
        shouldAlwaysHideAddAccount: Bool = false,
        showPlaceholderToolbarIcon: Bool = false
    ) {
        self.accounts = accounts
        self.activeAccountId = activeAccountId
        self.allowLockAndLogout = allowLockAndLogout
        self.isVisible = isVisible
        self.shouldAlwaysHideAddAccount = shouldAlwaysHideAddAccount
        self.showPlaceholderToolbarIcon = showPlaceholderToolbarIcon
    }

    // MARK: Static Functions

    static func empty(
        allowLockAndLogout: Bool = false,
        shouldAlwaysHideAddAccount: Bool = false,
        showPlaceholderToolbarIcon: Bool = false
    ) -> Self {
        ProfileSwitcherState(
            accounts: [],
            activeAccountId: nil,
            allowLockAndLogout: allowLockAndLogout,
            isVisible: false,
            shouldAlwaysHideAddAccount: shouldAlwaysHideAddAccount,
            showPlaceholderToolbarIcon: showPlaceholderToolbarIcon
        )
    }

    // MARK: Functions

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

    /// Sets the visibility of the profiles view and updates accessibility focus
    ///
    /// - Parameter visible: the intended visibility of the view
    ///
    mutating func setIsVisible(_ visible: Bool) {
        if !visible {
            hasSetAccessibilityFocus = false
        }
        isVisible = visible
    }
}
