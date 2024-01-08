// MARK: - AppContext

/// A type describing the context that the app is running within.
///
public enum AppContext {
    /// The main app is running.
    case mainApp

    /// The app is running within an extension.
    case appExtension
}
