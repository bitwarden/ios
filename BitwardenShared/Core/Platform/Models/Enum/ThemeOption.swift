import UIKit

// MARK: - ThemeOption

/// An enum listing the display theme options.
///
public enum ThemeOption: String {
    /// Use the dark theme.
    case dark

    /// Use the system settings.
    case `default`

    /// Use the light theme.
    case light

    // MARK: Type Properties

    /// The ordered list of options to display in the menu.
    static let allCases: [ThemeOption] = [.default, .light, .dark]

    // MARK: Properties

    /// The color theme to set the status bar to.
    var statusBarStyle: UIStatusBarStyle {
        switch self {
        case .dark:
            .lightContent
        case .default:
            .default
        case .light:
            .darkContent
        }
    }

    /// The name of the type to display in the alert.
    var title: String {
        switch self {
        case .dark:
            Localizations.dark
        case .default:
            Localizations.defaultSystem
        case .light:
            Localizations.light
        }
    }

    /// The value to use to actually set the app's theme.
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .dark:
            .dark
        case .default:
            .unspecified
        case .light:
            .light
        }
    }

    /// The value to save to the local storage.
    var value: String? {
        switch self {
        case .dark:
            "dark"
        case .default:
            nil
        case .light:
            "light"
        }
    }

    // MARK: Initialization

    /// Initialize a `ThemeOption`.`
    ///
    /// - Parameter appTheme: The raw value string of the custom selection, or `nil` for default.
    ///
    init(_ appTheme: String?) {
        if let appTheme {
            self = .init(rawValue: appTheme) ?? .default
        } else {
            self = .default
        }
    }
}
