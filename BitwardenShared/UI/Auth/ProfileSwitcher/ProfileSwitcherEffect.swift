// MARK: - ProfileSwitcherAccessibilityEffect

/// An enum for accessibility driven Profile Switcher Effects.
enum ProfileSwitcherAccessibilityEffect: Equatable {
    /// The account should be locked.
    case lock(ProfileSwitcherItem)

    /// The account should be set to active.
    case select(ProfileSwitcherItem)
}

// MARK: - ProfileSwitcherEffect

/// Effects that can be processed by a processor wrapping the ProfileSwitcherState.
enum ProfileSwitcherEffect: Equatable {
    /// An account row accessibility action was triggered.
    case accessibility(ProfileSwitcherAccessibilityEffect)

    /// An account row item was long pressed.
    case accountLongPressed(ProfileSwitcherItem)

    /// An account row item was pressed.
    case accountPressed(ProfileSwitcherItem)

    /// The add account row was pressed
    case addAccountPressed

    /// A row appeared
    case rowAppeared(ProfileSwitcherRowState.RowType)
}
