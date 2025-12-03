import Foundation

/// Utility and factory methods for handling test harness shared resources.
///
public class TestHarnessResources {
    /// The language code at initialization.
    public static var initialLanguageCode: String?

    /// Override SwiftGen's lookup function in order to determine the language manually.
    ///
    /// - Parameters:
    ///   - key: The localization key.
    ///   - table: The localization table.
    ///   - fallbackValue: The fallback value if the key is not found.
    /// - Returns: The localized string.
    ///
    public static func localizationFunction(key: String, table: String, fallbackValue: String) -> String {
        if let languageCode = initialLanguageCode,
           let path = Bundle(for: TestHarnessResources.self).path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: fallbackValue, table: table)
        }
        return Bundle.main.localizedString(forKey: key, value: fallbackValue, table: table)
    }
}
