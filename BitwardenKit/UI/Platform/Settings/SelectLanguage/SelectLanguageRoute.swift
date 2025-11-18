/// A route to a particular part of the Select Language flow.
///
public enum SelectLanguageRoute: Equatable, Hashable, Sendable {
    /// A route that dismisses the current view.
    case dismiss

    /// A route that opens the Select Language view, with a particular language having been selected.
    case open(currentLanguage: LanguageOption)
}
