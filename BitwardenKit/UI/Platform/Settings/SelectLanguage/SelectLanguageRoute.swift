/// A route to a particular part of the Select Language flow.
///
public enum SelectLanguageRoute: Equatable, Hashable, Sendable {
    /// A route that dismisses the current view.
    case dismiss

    /// A route that shows the Select Language view.
    case showSelectLanguage
}
