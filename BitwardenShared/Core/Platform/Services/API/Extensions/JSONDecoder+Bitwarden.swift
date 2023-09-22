import Foundation

extension JSONDecoder {
    // MARK: Types

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

    // MARK: Static Properties

    /// The default `JSONDecoder` used to decode JSON payloads throughout the app.
    static let defaultDecoder: JSONDecoder = {
        let dateFormatterWithFractionalSeconds = ISO8601DateFormatter()
        dateFormatterWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom { dateDecoder in
            let container = try dateDecoder.singleValueContainer()
            let stringValue = try container.decode(String.self)

            // ISO8601DateFormatter supports ISO 8601 dates with or without fractional seconds, but
            // not both at the same time 🙃. Since the API contains both formats with the more
            // common containing fractional seconds, attempt to parse that first and fall back to
            // parsing without fractional seconds.
            if let date = dateFormatterWithFractionalSeconds.date(from: stringValue) {
                return date
            } else if let date = dateFormatter.date(from: stringValue) {
                return date
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unable to decode date with value '\(stringValue)'"
                )
            }
        }
        return jsonDecoder
    }()

    /// A `JSONDecoder` instance that handles handles snake_case, PascalCase or camelCase keys.
    static let pascalOrSnakeCaseDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .custom { keys in
            let key = keys.last!.stringValue
            let camelCaseKey: String
            if key.contains("_") {
                // Handle snake_case.
                camelCaseKey = key.lowercased()
                    .split(separator: "_")
                    .enumerated()
                    .map { $0.offset > 0 ? $0.element.capitalized : $0.element.lowercased() }
                    .joined()
            } else {
                // Handle PascalCase or camelCase.
                camelCaseKey = key.prefix(1).lowercased() + key.dropFirst()
            }
            return AnyKey(stringValue: camelCaseKey)
        }
        return decoder
    }()
}
