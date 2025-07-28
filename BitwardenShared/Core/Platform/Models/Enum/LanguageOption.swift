import BitwardenResources
import Foundation

// MARK: - LanguageOption

/// An enum listing all the language options, either default (system settings) or any of the currently available
/// localizable files.
public enum LanguageOption: Equatable, Sendable {
    /// Use the system settings.
    case `default`

    /// Specify the language using the language code.
    case custom(languageCode: String)

    // MARK: Type Properties

    /// All the language options.
    static let allCases: [LanguageOption] = [.default] + languageCodes.map { .custom(languageCode: $0) }

    /// Ideally we could dynamically fetch all the language codes available as localizable files
    /// by calling `Bundle.main.localizations`, but since the Bundle currently doesn't
    /// return reliable results for some reason, we have to hard-code the languages for now.
    private static let languageCodes =
        [
            "af",
            "be",
            "bg",
            "ca",
            "cs",
            "da",
            "de",
            "el",
            "en",
            "en-GB",
            "eo",
            "es",
            "et",
            "fa",
            "fi",
            "fr",
            "he",
            "hi",
            "hr",
            "hu",
            "id",
            "it",
            "ja",
            "ko",
            "lv",
            "ml",
            "nb",
            "nl",
            "pl",
            "pt-BR",
            "pt-PT",
            "ro",
            "ru",
            "sk",
            "sv",
            "th",
            "tr",
            "uk",
            "vi",
            "zh-Hans",
            "zh-Hant",
        ]

    // MARK: Properties

    /// The title of the language option as it appears in the list of options.
    var title: String {
        switch self {
        case .default:
            Localizations.defaultSystem
        case let .custom(languageCode: languageCode):
            // Create a Locale using the language code in order to extract
            // its full reader-friendly name.
            Locale(identifier: languageCode)
                .localizedString(forIdentifier: languageCode)?
                .localizedCapitalized ??
                Locale.current
                .localizedString(forIdentifier: languageCode)?
                .localizedCapitalized ?? ""
        }
    }

    /// The two letter language code representation of the language, or `nil` for the system default.
    var value: String? {
        switch self {
        case .default:
            nil
        case let .custom(languageCode: languageCode):
            languageCode
        }
    }

    // MARK: Initialization

    /// Initialize a `LanguageOption`.`
    ///
    /// - Parameter languageCode: The language code of the custom selection, or `nil` for default.
    ///
    init(_ languageCode: String?) {
        if let languageCode {
            self = .custom(languageCode: languageCode)
        } else {
            self = .default
        }
    }
}

// MARK: - Identifiable

extension LanguageOption: Identifiable {
    public var id: String {
        switch self {
        case .default:
            "default"
        case let .custom(languageCode: languageCode):
            languageCode
        }
    }
}

// MARK: - Hashable

extension LanguageOption: Hashable {}
