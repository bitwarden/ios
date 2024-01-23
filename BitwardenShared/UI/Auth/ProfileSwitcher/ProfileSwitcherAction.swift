import SwiftUI

// MARK: - ProfileSwitcherAction

/// Actions that can be processed by a `ProfileSwitcherProcessor`.
enum ProfileSwitcherAction: Equatable {
    /// An account row item was long pressed.
    case accountLongPressed(ProfileSwitcherItem)

    /// An account row item was pressed.
    case accountPressed(ProfileSwitcherItem)

    /// The add account button was pressed.
    case addAccountPressed

    /// The user tapped the background area of the view
    case backgroundPressed

    /// An action to toggle the visibility of the profile switcher view.
    case requestedProfileSwitcher(visible: Bool)

    /// The offset of the scrollView Changed
    case scrollOffsetChanged(CGPoint)
}
