import Foundation

// MARK: - SafariExtensionBridgeRequest

public struct SafariExtensionBridgeRequest: Codable, Equatable {
    public var id: String
    public var request: SafariExtensionRequest

    public init(id: String, request: SafariExtensionRequest) {
        self.id = id
        self.request = request
    }
}

// MARK: - SafariExtensionBridgeResponse

public struct SafariExtensionBridgeResponse: Codable, Equatable {
    public var id: String
    public var response: SafariExtensionResponse?
    public var errorMessage: String?

    public init(id: String, response: SafariExtensionResponse?, errorMessage: String?) {
        self.id = id
        self.response = response
        self.errorMessage = errorMessage
    }
}

// MARK: - SafariExtensionBridgeCodec

public enum SafariExtensionBridgeCodec {
    public static func decodeRequest(from message: Any?) -> SafariExtensionBridgeRequest? {
        if let wrappedMessage = (message as? [String: Any])?["message"],
           let decoded = decodeRequest(from: wrappedMessage) {
            return decoded
        }

        if let message,
           JSONSerialization.isValidJSONObject(message),
           let data = try? JSONSerialization.data(withJSONObject: message) {
            return try? makeDecoder().decode(SafariExtensionBridgeRequest.self, from: data)
        }

        if let message = message as? String,
           let data = message.data(using: .utf8) {
            return try? makeDecoder().decode(SafariExtensionBridgeRequest.self, from: data)
        }

        return nil
    }

    public static func encodeResponse(
        requestID: String,
        response: SafariExtensionResponse,
        errorMessage: String? = nil,
    ) throws -> String {
        try encodeBridgeResponse(
            SafariExtensionBridgeResponse(
                id: requestID,
                response: response,
                errorMessage: errorMessage,
            )
        )
    }

    public static func encodeErrorResponse(
        requestID: String,
        errorMessage: String,
    ) throws -> String {
        try encodeBridgeResponse(
            SafariExtensionBridgeResponse(
                id: requestID,
                response: nil,
                errorMessage: errorMessage,
            )
        )
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(Double.self) {
                return Date(timeIntervalSinceReferenceDate: value)
            }
            let value = try container.decode(String.self)
            let withFractionalSeconds = ISO8601DateFormatter()
            withFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFractionalSeconds.date(from: value) {
                return date
            }
            let withoutFractionalSeconds = ISO8601DateFormatter()
            withoutFractionalSeconds.formatOptions = [.withInternetDateTime]
            if let date = withoutFractionalSeconds.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO 8601 date string."
            )
        }
        return decoder
    }

    private static func encodeBridgeResponse(_ bridgeResponse: SafariExtensionBridgeResponse) throws -> String {
        let data = try JSONEncoder().encode(bridgeResponse)
        guard let message = String(data: data, encoding: .utf8) else {
            throw CocoaError(.coderInvalidValue)
        }
        return message
    }
}
