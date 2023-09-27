import Foundation

/// Errors thrown by the `TokenParser`.
///
enum TokenParserError: Error {
    /// The token was invalid and unable to be parsed.
    case invalidToken
}

// MARK: - TokenParser

/// A helper object that can parse the payload of a JWT token.
///
enum TokenParser {
    /// Parses the payload of a JWT token.
    ///
    /// - Parameter token: The token to parse.
    /// - Returns: The parsed values of the JWT token payload.
    ///
    static func parseToken(_ token: String) throws -> TokenPayload {
        let tokenParts = token.split(separator: ".")
        guard tokenParts.count == 3 else {
            throw TokenParserError.invalidToken
        }

        let payload = String(tokenParts[1])
        guard let payloadData = try Data(base64Encoded: payload.urlDecoded()) else {
            throw TokenParserError.invalidToken
        }

        return try JSONDecoder.snakeCaseDecoder.decode(TokenPayload.self, from: payloadData)
    }
}
