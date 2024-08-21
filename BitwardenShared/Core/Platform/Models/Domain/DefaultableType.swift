import Foundation

// MARK: - DefaultableType

/// A wrapper around any `CaseIterable` and `Menuable` type that can be set to a default value.
enum DefaultableType<T: Menuable & Sendable>: Menuable, Sendable {
    // MARK: Cases

    /// placeholder default value of the type.
    case `default`
    case custom(T)

    // MARK: Properties

    var localizedName: String {
        switch self {
        case .default:
            T.defaultValueLocalizedName
        case let .custom(value):
            value.localizedName
        }
    }

    /// The custom wrapped value if the type is `.custom`.
    var customValue: T? {
        guard case let .custom(value) = self else { return nil }
        return value
    }
}

extension DefaultableType: CaseIterable where T: CaseIterable {
    // MARK: Type Properties

    static var allCases: [DefaultableType<T>] {
        [.default] + T.allCases.map(DefaultableType.custom)
    }
}
