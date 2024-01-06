// MARK: - SelectLanguageState

/// The state used to present the `SelectLanguageView`.
struct SelectLanguageState: Equatable {
    /// The currently selected language.
    var currentLanguage: LanguageOption = .default
}
