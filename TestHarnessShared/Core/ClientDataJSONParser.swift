import BitwardenKit
import Foundation

// MARK: - ClientDataJSONParser

/// Parses a WebAuthn `clientDataJSON` payload to extract the fields a relying party checks when
/// completing a registration ceremony: the collected client data's `type` and `challenge`.
///
enum ClientDataJSONParser {
    // MARK: Types

    /// The fields extracted from a `clientDataJSON` payload.
    struct ParsedClientData: Equatable {
        /// The challenge echoed back by the authenticator, decoded from base64url.
        let challenge: Data

        /// The WebAuthn ceremony type, e.g. `"webauthn.create"`.
        let type: String
    }

    /// Errors that can occur while parsing a `clientDataJSON` payload.
    enum ParsingError: Error, Equatable, LocalizedError {
        /// The payload was not valid JSON, or not a JSON object.
        case malformedJSON

        /// The JSON object did not contain a `type` field.
        case missingType

        /// The JSON object did not contain a `challenge` field.
        case missingChallenge

        /// The `challenge` field was not valid base64url.
        case malformedChallengeEncoding

        var errorDescription: String? {
            switch self {
            case .malformedJSON:
                Localizations.malformedClientDataJSONReceived
            case .missingType:
                Localizations.missingClientDataTypeReceived
            case .missingChallenge:
                Localizations.missingClientDataChallengeReceived
            case .malformedChallengeEncoding:
                Localizations.malformedClientDataChallengeReceived
            }
        }
    }

    // MARK: Methods

    /// Parses the `type` and `challenge` fields out of a WebAuthn `clientDataJSON` payload.
    ///
    /// - Parameter data: The raw `clientDataJSON` bytes.
    /// - Returns: The extracted type and challenge.
    ///
    static func parse(fromClientDataJSON data: Data) throws -> ParsedClientData {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ParsingError.malformedJSON
        }
        guard let type = object["type"] as? String else {
            throw ParsingError.missingType
        }
        guard let challengeBase64URL = object["challenge"] as? String else {
            throw ParsingError.missingChallenge
        }
        guard let challenge = try? Data(base64urlEncoded: challengeBase64URL) else {
            throw ParsingError.malformedChallengeEncoding
        }

        return ParsedClientData(challenge: challenge, type: type)
    }
}
