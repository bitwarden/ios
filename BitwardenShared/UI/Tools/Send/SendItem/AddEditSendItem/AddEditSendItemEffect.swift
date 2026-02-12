// MARK: - AddEditSendItemEffect

/// Effects that can be processed by a `AddEditSendItemProcessor`.
///
enum AddEditSendItemEffect: Equatable {
    /// The copy link button was pressed.
    case copyLinkPressed

    /// The copy password button was pressed.
    case copyPasswordPressed

    /// The delete button was pressed.
    case deletePressed

    /// Any initial data for the view should be loaded.
    case loadData

    /// A Profile Switcher Effect.
    case profileSwitcher(ProfileSwitcherEffect)

    /// The remove password button was pressed.
    case removePassword

    /// The save button was pressed.
    case savePressed

    /// The share link button was pressed.
    case shareLinkPressed
}
