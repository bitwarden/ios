// MARK: - SettingsEvent

/// An event to be handled by the SettingsCoordinator.
///
enum SettingsEvent: Equatable {
    /// When an `AuthAction` occurs.
    case authAction(AuthAction)

    /// When the user has deleted their account.
    case didDeleteAccount
}
