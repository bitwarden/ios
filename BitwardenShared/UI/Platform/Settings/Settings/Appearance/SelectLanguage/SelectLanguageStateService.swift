/// A protocol for a State Service that handles language state.
public protocol LanguageStateService: AnyObject {
    /// The language option currently selected for the app.
    var appLanguage: LanguageOption { get set }
}

/// Protocol for an object that provides a `StateService`.
///
public protocol HasLanguageStateService {
    /// The service used by the application to manage account state.
    var languageStateService: LanguageStateService { get }
}
