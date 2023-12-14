import Foundation

// MARK: - DefaultableType

/// A wrapper around any `CaseIterable` and `Menuable` type that can be set to a default value.
enum DefaultableType<T: CaseIterable & Menuable>: CaseIterable, Menuable {
    // MARK: Cases

    /// placeholder default value of the type like `default` or `--select--`
    /// - Parameter string:  custom localizable title value for this default case, defaults to  `Default`.
    case `default`(String? = nil)
    case custom(T)

    // MARK: Type Properties

    static var allCases: [DefaultableType<T>] {
        [.default()] + T.allCases.map(DefaultableType.custom)
    }

    // MARK: Properties

    var localizedName: String {
        switch self {
        case let .default(customizedName):
            customizedName ?? Localizations.default
        case let .custom(value):
            value.localizedName
        }
    }
}
