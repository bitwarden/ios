import BitwardenSdk

// MARK: - SendAuthType

/// An enum representing the authentication type for a Send in API models.
/// Maps to the server's integer representation of auth types.
///
enum SendAuthType: Int, Codable, Equatable, Sendable {
    /// Email-based OTP authentication (specific people).
    case email = 0

    /// Password-based authentication.
    case password = 1

    /// No authentication required (anyone with the link).
    case none = 2

    // MARK: Properties

    /// Converts to the SDK's `AuthType`.
    var sdkAuthType: AuthType {
        switch self {
        case .none:
            .none
        case .email:
            .email
        case .password:
            .password
        }
    }

    // MARK: Initialization

    /// Creates a `SendAuthType` from the SDK's `AuthType`.
    ///
    /// - Parameter authType: The SDK `AuthType` to convert.
    ///
    init(authType: AuthType) {
        switch authType {
        case .none:
            self = .none
        case .email:
            self = .email
        case .password:
            self = .password
        }
    }
}
