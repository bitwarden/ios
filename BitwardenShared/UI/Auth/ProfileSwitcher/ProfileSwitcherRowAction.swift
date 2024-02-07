// MARK: - ProfileSwitcherRowAction

/// Actions that can be processed by a `ProfileSwitcherProcessor`.
enum ProfileSwitcherRowAction: Equatable {
    /// An account row accessibility action was triggered.
    case accessibility(ProfileSwitcherAccessibilityAction)
}

// MARK: - ProfileSwitcherRowEffect

/// Actions that can be processed by a `ProfileSwitcherProcessor`.
enum ProfileSwitcherRowEffect: Equatable {
    /// An account row accessibility action was triggered.
    case accessibility(ProfileSwitcherAccessibilityEffect)

    /// An account row item was long pressed.
    case longPressed(ProfileSwitcherRowState.RowType)

    /// An account row item was pressed.
    case pressed(ProfileSwitcherRowState.RowType)
}
