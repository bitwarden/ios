import Foundation

extension JSONEncoder {
    // MARK: Static Properties

    /// `AnyKey` is a `CodingKey` type that can be used for encoding and decoding keys for custom
    /// key decoding strategies.
    struct AnyKey: CodingKey {
        let stringValue: String
        let intValue: Int?

        init(stringValue: String) {
            self.stringValue = stringValue
            intValue = nil
        }

        init(intValue: Int) {
            stringValue = String(intValue)
            self.intValue = intValue
        }
    }
    
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
    static let cxpEncoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Int(date.timeIntervalSince1970))
        }
        jsonEncoder.keyEncodingStrategy = .custom { keys in
            let key = keys.last!.stringValue
            return AnyKey(stringValue: customTransformCodingKeyForCXP(key: key))
        }
        return jsonEncoder
    }()

    // MARK: Static Functions

    /// Transforms the keys from CXP format handled by the Bitwarden SDK into the keys that Apple expects.
    static func customTransformCodingKeyForCXP(key: String) -> String {
        return switch key {
        case "credentialID":
            "credentialId"
        case "rpID":
            "rpId"
        default:
            key
        }
    }

    /// Transforms a snake_case, PascalCase or camelCase key into camelCase.
    static func keyToCamelCase(key: String) -> String {
        if key.contains("_") {
            // Handle snake_case.
            return key.lowercased()
                .split(separator: "_")
                .enumerated()
                .map { $0.offset > 0 ? $0.element.capitalized : $0.element.lowercased() }
                .joined()
        }

        // Handle PascalCase or camelCase.
        return key.prefix(1).lowercased() + key.dropFirst()
    }
}
