import SwiftUI

// MARK: - ProfileSwitcherState

/// An object that defines the current state of profile selection.
///
struct ProfileSwitcherState: Equatable {
    // MARK: Static Properties

    /// An empty state with an empty currenct account profile
    static var empty: Self {
        ProfileSwitcherState(
            currentAccountProfile: ProfileSwitcherItem(),
            isVisible: false
        )
    }

    // MARK: Properties

    /// A list of alternate accounts/profiles
    var alternateAccounts: [ProfileSwitcherItem]

    // MARK: Private(set) Properties

    /// The account profile currently in use
    private(set)
    var currentAccountProfile: ProfileSwitcherItem

    /// A flag for view visibility
    var isVisible: Bool

    /// The observed offset of the scrollView
    var scrollOffset: CGPoint

    // MARK: Derived Properties

    /// All accounts, with the current account last
    var accounts: [ProfileSwitcherItem] {
        alternateAccounts
            .filter { $0.userId != currentAccountProfile.userId }
            + [currentAccountProfile]
    }

    // MARK: Initialization

    /// Initialize the `ProfileSwitcherState`
    ///
    /// - Parameters:
    ///   - alternateAccounts: A list of alternate `ProfileSwitcherItem` profiles
    ///   - currentAccountProfile: The current `ProfileSwitcherItem` profile
    ///   - isVisible: The visibility of the view
    ///   - scrollOffset: The offset of the scroll view
    ///
    init(
        alternateAccounts: [ProfileSwitcherItem] = [],
        currentAccountProfile: ProfileSwitcherItem,
        isVisible: Bool,
        scrollOffset: CGPoint = .zero
    ) {
        self.alternateAccounts = alternateAccounts
        self.currentAccountProfile = currentAccountProfile
        self.isVisible = isVisible
        self.scrollOffset = scrollOffset
    }

    // MARK: Functions

    /// A  mutating method to select an account by its identifier
    mutating func selectAccount(_ selected: ProfileSwitcherItem) {
        guard alternateAccounts.contains(where: { $0.userId == selected.userId }) else { return }
        alternateAccounts = alternateAccounts
            .filter { $0.userId != selected.userId }
            + [currentAccountProfile]
        currentAccountProfile = selected
    }
}
