/// Actions pending to execute given triggering an `AppIntent` previously.
/// Used for example when the app is in background when the `AppIntent`
/// is executed and then the user goes back to the app and the
/// UI needs to be updated / navigation needs to be performed.
public enum PendingAppIntentAction: Codable, Equatable {
    /// Lock the account which user ID is passed as parameter, `nil` if current.
    case lock(String?)

    /// Lock all accounts.
    case lockAll

    /// Opens the generator view.
    case openGenerator

    /// Whether or not the current action is `.lock`.
    func isLock() -> Bool {
        guard case .lock = self else {
            return false
        }
        return true
    }
}
