/// Actions that can be processed by a `SettingsProcessor`.
///
enum SettingsAction: Equatable {
    /// The about button was pressed.
    case aboutPressed

    /// The account security button was pressed.
    case accountSecurityPressed

    /// The appearance button was pressed.
    case appearancePressed

    /// The auto-fill button was pressed.
    case autoFillPressed

    /// The close button was tapped.
    case dismiss

    /// The other button was pressed.
    case otherPressed

    /// The vault button was pressed.
    case vaultPressed
}
