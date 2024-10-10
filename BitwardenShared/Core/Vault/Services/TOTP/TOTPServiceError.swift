import Foundation

/// Enum representing errors in the TOTP Service.
///
enum TOTPServiceError: Error, Equatable, CustomNSError {
    /// `invalidKeyFormat` is thrown when the TOTP key is not in a recognized or valid format.
    case invalidKeyFormat

    /// `unableToGenerateCode` is thrown when the TOTP code cannot be generated.
    case unableToGenerateCode(_ errorDescription: String?)

    /// The user-info dictionary.
    public var errorUserInfo: [String: Any] {
        switch self {
        case .invalidKeyFormat:
            return [:]
        case let .unableToGenerateCode(description):
            guard let description else {
                return [:]
            }
            return ["Description": description]
        }
    }
}
