import Foundation

public extension JSONEncoder {
    // MARK: Static Properties

    /// The default `JSONEncoder` used to encode JSON payloads throughout the app.
    static let defaultEncoder: JSONEncoder = {
        let dateFormatterWithFractionalSeconds = ISO8601DateFormatter()
        dateFormatterWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(dateFormatterWithFractionalSeconds.string(from: date))
        }
        return jsonEncoder
    }()

    /// The default `JSONEncoder` used to encode JSON payloads when in Credential Exchange flow.
    static let cxfEncoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Int(date.timeIntervalSince1970))
        }
        jsonEncoder.keyEncodingStrategy = .custom { keys in
            let key = keys.last!.stringValue
            return AnyKey(stringValue: customTransformCodingKeyForCXF(key: key))
        }
        return jsonEncoder
    }()

    // MARK: Static Functions

    /// Transforms the keys from Credential Exchange format handled by the Bitwarden SDK
    /// into the keys that Apple expects.
    static func customTransformCodingKeyForCXF(key: String) -> String {
        return switch key {
        case "credentialID":
            "credentialId"
        case "rpID":
            "rpId"
        default:
            key
        }
    }
}
