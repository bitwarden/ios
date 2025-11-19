import Foundation

/// Utility and factory methods for handling shared resources
///
public class Resources {
    /// The language code at initialization.
    public static var initialLanguageCode: String?

    /// Override SwiftGen's lookup function in order to determine the language manually.
    public static func localizationFunction(key: String, table: String, fallbackValue: String) -> String {
        if let languageCode = initialLanguageCode,
           let path = Bundle(for: Resources.self).path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: fallbackValue, table: table)
        }
        return Bundle.main.localizedString(forKey: key, value: fallbackValue, table: table)
    }
}
