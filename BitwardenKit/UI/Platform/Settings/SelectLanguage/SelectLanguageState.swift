// MARK: - SelectLanguageState

/// The state used to present the `SelectLanguageView`.
public struct SelectLanguageState: Equatable {
    /// The currently selected language.
    public var currentLanguage: LanguageOption = .default

    public init() {}

    public init(currentLanguage: LanguageOption) {
        self.currentLanguage = currentLanguage
    }
}
