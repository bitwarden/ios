import Foundation

/// Enum representing errors in the TOTP Service.
///
public enum TOTPServiceError: Error, Equatable, CustomNSError {
    /// `unableToGenerateCode` is thrown when the TOTP code cannot be generated.
    case unableToGenerateCode(_ errorDescription: String?)

    /// The user-info dictionary.
    public var errorUserInfo: [String: Any] {
        switch self {
        case let .unableToGenerateCode(description):
            guard let description else {
                return [:]
            }
            return ["Description": description]
        }
    }
}
