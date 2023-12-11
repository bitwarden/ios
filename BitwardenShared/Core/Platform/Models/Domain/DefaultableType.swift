import Foundation

// MARK: - DefaultableType

/// A wrapper around any `CaseIterable` and `Menuable` type that can be set to a default value.
enum DefaultableType<T: CaseIterable & Menuable>: CaseIterable, Menuable {
    // MARK: Cases

    case `default`
    case custom(T)

    // MARK: Type Properties

    static var allCases: [DefaultableType<T>] {
        [.default] + T.allCases.map(DefaultableType.custom)
    }

    // MARK: Properties

    var localizedName: String {
        switch self {
        case .default:
            Localizations.default
        case let .custom(value):
            value.localizedName
        }
    }
}
