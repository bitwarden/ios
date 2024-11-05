// MARK: - AccountSetupFlow

/// An enum that describes the flow in which account setup tasks are performed in.
///
public enum AccountSetupFlow: Equatable {
    /// The user is setting up their account in the create account flow.
    case createAccount

    /// The user is setting up their account from the app's settings.
    case settings
}
