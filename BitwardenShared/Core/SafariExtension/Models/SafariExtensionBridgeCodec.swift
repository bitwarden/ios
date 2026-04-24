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
        if let message,
           JSONSerialization.isValidJSONObject(message),
           let data = try? JSONSerialization.data(withJSONObject: message) {
            return try? JSONDecoder().decode(SafariExtensionBridgeRequest.self, from: data)
        }

        if let message = message as? String,
           let data = message.data(using: .utf8) {
            return try? JSONDecoder().decode(SafariExtensionBridgeRequest.self, from: data)
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

    private static func encodeBridgeResponse(_ bridgeResponse: SafariExtensionBridgeResponse) throws -> String {
        let data = try JSONEncoder().encode(bridgeResponse)
        guard let message = String(data: data, encoding: .utf8) else {
            throw CocoaError(.coderInvalidValue)
        }
        return message
    }
}
