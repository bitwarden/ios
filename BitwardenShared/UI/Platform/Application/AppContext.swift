// MARK: - AppContext

/// A type describing the context that the app is running within.
///
public enum AppContext: Equatable {
    /// The app is running within the app extension.
    case appExtension

    /// An `AppIntent` is running.
    case appIntent(AppIntentAction)

    /// The main app is running.
    case mainApp

    /// Whether the current context is from an `AppIntent`.
    /// - Returns: `true` if the context is from an `AppIntent`, `false` otherwise.
    func isAppIntent() -> Bool {
        return if case .appIntent = self {
            true
        } else {
            false
        }
    }

    /// Whether the current context is from an `AppIntent` and the action is the one provided.
    /// - Parameter action: The action to check if it's the current one.
    /// - Returns: `true` if the intent action is the one being passed, `false` otherwise.
    func isAppIntentAction(_ action: AppIntentAction) -> Bool {
        guard case let .appIntent(intentAction) = self else {
            return false
        }
        return intentAction == action
    }
}

/// Actions that the `AppIntent` is intended for. Used in the `AppContext`.
public enum AppIntentAction {
    /// Locks all users.
    case lockAll

    /// Logs out all users.
    case logoutAll
}
