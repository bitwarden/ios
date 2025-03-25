import Foundation

@available(iOS 16, *)
enum AppIntentError: Error, CustomLocalizedStringResourceConvertible {
    case notAllowed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notAllowed:
            "ThisOperationIsNotAllowedOnThisAccount"
        }
    }
}
