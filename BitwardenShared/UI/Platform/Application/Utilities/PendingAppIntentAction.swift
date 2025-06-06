/// Actions pending to execute given triggering an `AppIntent` previously.
/// Used for example when the app is in background when the `AppIntent`
/// is executed and then the user goes back to the app and the
/// UI needs to be updated / navigation needs to be performed.
public enum PendingAppIntentAction: Codable, Equatable {
    /// Lock all accounts.
    case lockAll

    /// Logs out all accounts.
    case logOutAll

    /// Opens the generator view.
    case openGenerator
}
