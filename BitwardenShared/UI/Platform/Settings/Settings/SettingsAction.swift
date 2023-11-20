/// Actions that can be processed by a `SettingsProcessor`.
///
enum SettingsAction: Equatable {
    /// The account security button was pressed.
    case accountSecurityPressed

    /// The auto-fill button was pressed.
    case autoFillPressed

    /// The other button was pressed.
    case otherPressed
}
