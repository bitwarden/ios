// MARK: - ProfileSwitcherEffect

/// Effects that can be processed by a processor wrapping the ProfileSwitcherState.
enum ProfileSwitcherEffect {
    /// A row appeared
    case rowAppeared(ProfileSwitcherRowState.RowType)
}
