// MARK: - SelectLanguageState

/// The state used to present the `SelectLanguageView`.
public struct SelectLanguageState: Equatable {
    /// The currently selected language.
    public var currentLanguage: LanguageOption

    /// Creates a new `SelectLanguageState` with a specified language option.
    /// If none is specified, then it is set to `LanguageOption.default`.
    ///
    /// - Parameters:
    ///   - currentLanguage: The currently selected language.
    ///
    public init(currentLanguage: LanguageOption = .default) {
        self.currentLanguage = currentLanguage
    }
}
