// MARK: - ProfileSwitcherRowAction

/// Actions that can be processed by a `ProfileSwitcherProcessor`.
enum ProfileSwitcherRowAction: Equatable {
    /// An account row item was long pressed.
    case longPressed(ProfileSwitcherRowState.RowType)

    /// An account row item was pressed.
    case pressed(ProfileSwitcherRowState.RowType)
}
