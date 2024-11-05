import SwiftUI

// MARK: - ProfileSwitcherAccessibilityAction

/// An enum for accessibility driven actions.
enum ProfileSwitcherAccessibilityAction: Equatable {
    /// The account should be logged out.
    case logout(ProfileSwitcherItem)
}

// MARK: - ProfileSwitcherAction

/// Actions that can be processed by a `ProfileSwitcherProcessor`.
enum ProfileSwitcherAction: Equatable {
    /// An account row accessibility action was triggered.
    case accessibility(ProfileSwitcherAccessibilityAction)

    /// The user tapped the background area of the view
    case backgroundPressed
}
