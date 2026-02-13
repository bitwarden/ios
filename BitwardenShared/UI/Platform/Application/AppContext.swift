// MARK: - AppContext

/// A type describing the context that the app is running within.
///
public enum AppContext: Equatable {
    /// The app is running within the app extension.
    case appExtension

    /// The main app is running.
    case mainApp
}

extension AppContext {
    /// A safe string representation of the current app context
    var appContextName: String {
        switch self {
        case .appExtension:
            "App Extension"
        case .mainApp:
            "Main App"
        }
    }
}
