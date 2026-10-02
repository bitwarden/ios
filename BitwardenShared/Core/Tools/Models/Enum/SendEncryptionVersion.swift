import BitwardenKit
import BitwardenSdk
import OSLog

// MARK: - SendEncryptionVersion

/// An enum representing the encryption version of a Send's item data, in API models.
///
enum SendEncryptionVersion: Int, Codable, Equatable, Sendable {
    /// An unknown encryption version.
    case unknown = -1

    /// V1 encryption (field by field).
    case v1 = 1 // swiftlint:disable:this identifier_name

    // MARK: Properties

    /// Converts to the SDK's `SendEncryptionType`, or `nil` if the encryption version is unknown.
    var sdkEncryptionType: SendEncryptionType? {
        switch self {
        case .unknown:
            nil
        case .v1:
            .v1
        }
    }

    // MARK: Initialization

    /// Creates a `SendEncryptionVersion` from a decoder, defaulting to `.unknown` for unrecognized values.
    ///
    /// - Parameter decoder: The decoder to read data from.
    ///
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(RawValue.self)
        if let encryptionVersion = Self(rawValue: rawValue) {
            self = encryptionVersion
        } else {
            Logger.application.error("SendEncryptionVersion: Unknown encryption version received: \(rawValue)")
            self = .unknown
        }
    }

    /// Creates a `SendEncryptionVersion` from the SDK's `SendEncryptionType`.
    ///
    /// - Parameter encryptionType: The SDK `SendEncryptionType` to convert.
    ///
    init(encryptionType: SendEncryptionType) {
        switch encryptionType {
        case .v1:
            self = .v1
        }
    }
}

// MARK: - DefaultValueProvider

extension SendEncryptionVersion: DefaultValueProvider {
    static var defaultValue: SendEncryptionVersion { .v1 }
}
