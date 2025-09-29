// MARK: - SelectLanguageAction

/// Actions that can be processed by a `SelectLanguageProcessor`.
enum SelectLanguageAction: Equatable {
    /// The cancel button was tapped.
    case dismiss

    /// A language was selected.
    case languageTapped(LanguageOption)
}
