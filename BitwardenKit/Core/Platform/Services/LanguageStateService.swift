/// A protocol for a State Service that handles language state.
public protocol LanguageStateService: AnyObject { // sourcery: AutoMockable
    /// The language option currently selected for the app.
    var appLanguage: LanguageOption { get set }
}
