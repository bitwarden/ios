// MARK: - SelectLanguageState

/// The state used to present the `SelectLanguageView`.
public struct SelectLanguageState: Equatable {
    /// The currently selected language.
    public var currentLanguage: LanguageOption = .default

    /// Creates a new `SelectLanguageState` with the default language option.
    ///
    public init() {}

    /// Creates a new `SelectLanguageState` with a specified language option.
    ///
    /// - Parameters:
    ///   - currentLanguage: The currently selected language.
    ///
    public init(currentLanguage: LanguageOption) {
        self.currentLanguage = currentLanguage
    }
}
