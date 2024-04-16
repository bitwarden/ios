import BitwardenSdk
import Foundation

/// A route to a specific screen in the settings tab.
///
public enum SettingsRoute: Equatable, Hashable {
    /// A route to the about view.
    case about

    /// A route to the appearance screen.
    case appearance

    /// A route that dismisses the current view.
    case dismiss

    /// A route to view the select language view.
    ///
    /// - Parameter currentLanguage: The currently selected language option.
    ///
    case selectLanguage(currentLanguage: LanguageOption)

    /// A route to the settings screen.
    case settings

    /// A route to show the tutorial.
    case tutorial
}
