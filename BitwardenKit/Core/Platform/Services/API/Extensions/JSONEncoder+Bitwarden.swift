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
        return jsonEncoder
    }()
}
