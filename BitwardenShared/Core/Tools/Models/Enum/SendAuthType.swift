import BitwardenSdk
import OSLog

// MARK: - SendAuthType

/// An enum representing the authentication type for a Send in API models.
///
enum SendAuthType: Int, Codable, Equatable, Sendable {
    /// Email-based OTP authentication (specific people).
    case email = 0

    /// Password-based authentication.
    case password = 1

    /// No authentication required (anyone with the link).
    case none = 2

    /// An unknown auth type.
    case unknown = -1

    // MARK: Properties

    /// Converts to the SDK's `AuthType`.
    var sdkAuthType: AuthType {
        switch self {
        case .none, .unknown:
            .none
        case .email:
            .email
        case .password:
            .password
        }
    }

    // MARK: Initialization

    /// Creates a `SendAuthType` from a decoder, defaulting to `.unknown` for unrecognized values.
    ///
    /// - Parameter decoder: The decoder to read data from.
    ///
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(RawValue.self)
        if let authType = Self(rawValue: rawValue) {
            self = authType
        } else {
            Logger.application.error("SendAuthType: Unknown auth type received: \(rawValue)")
            self = .unknown
        }
    }

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
