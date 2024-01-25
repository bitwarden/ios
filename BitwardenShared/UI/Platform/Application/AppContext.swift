// MARK: - AppContext

/// A type describing the context that the app is running within.
///
public enum AppContext {
    /// The app is running within the app extension.
    case appExtension

    /// The main app is running.
    case mainApp
}
