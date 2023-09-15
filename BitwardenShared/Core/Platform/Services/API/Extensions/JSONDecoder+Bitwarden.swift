import Foundation

extension JSONDecoder {
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
}
