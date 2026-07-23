import Foundation

// MARK: - COSEKeyParser

/// Parses a WebAuthn attestation object to extract the credential ID and ES256 (P-256) public key
/// embedded in its authenticator data. This is intentionally not a general-purpose CBOR/COSE
/// decoder: it understands only the narrow structure Apple's platform authenticator produces
/// (a top-level `fmt`/`attStmt`/`authData` map, with an EC2/P-256/ES256 COSE key inside
/// `authData`'s attested credential data).
///
enum COSEKeyParser {
    // MARK: Types

    /// The credential ID and public key extracted from an attestation object.
    struct ParsedCredential: Equatable {
        /// The raw credential ID.
        let credentialId: Data

        /// The P-256 public key in ANSI X9.63 format (`0x04 || X || Y`), ready to be passed to
        /// `P256.Signing.PublicKey(x963Representation:)`.
        let publicKeyX963: Data
    }

    /// Errors that can occur while parsing an attestation object.
    enum ParsingError: Error, Equatable, LocalizedError {
        /// The top-level CBOR structure could not be decoded.
        case malformedTopLevelCBOR

        /// The top-level CBOR map did not contain an `authData` entry.
        case missingAuthData

        /// `authData` was too short to contain the expected fields.
        case authDataTooShort

        /// `authData`'s flags did not have the "attested credential data included" bit set.
        case missingAttestedCredentialData

        /// The credential ID length did not fit within the remaining `authData` bytes.
        case malformedCredentialIdLength

        /// The embedded COSE key could not be decoded or was missing required fields.
        case malformedCOSEKey

        /// The COSE key's `kty` field was not `2` (EC2).
        case unsupportedKeyType(Int)

        /// The COSE key's `alg` field was not `-7` (ES256).
        case unsupportedAlgorithm(Int)

        /// The COSE key's `crv` field was not `1` (P-256).
        case unsupportedCurve(Int)

        var errorDescription: String? {
            switch self {
            case .malformedTopLevelCBOR:
                Localizations.malformedTopLevelCBORReceived
            case .missingAuthData:
                Localizations.missingAuthDataReceived
            case .authDataTooShort:
                Localizations.authDataTooShortReceived
            case .missingAttestedCredentialData:
                Localizations.missingAttestedCredentialDataReceived
            case .malformedCredentialIdLength:
                Localizations.malformedCredentialIdLengthReceived
            case .malformedCOSEKey:
                Localizations.malformedCOSEKeyReceived
            case let .unsupportedKeyType(keyType):
                Localizations.unsupportedKeyTypeReceived(keyType)
            case let .unsupportedAlgorithm(algorithm):
                Localizations.unsupportedAlgorithmReceived(algorithm)
            case let .unsupportedCurve(curve):
                Localizations.unsupportedCurveReceived(curve)
            }
        }
    }

    // MARK: Methods

    /// Parses the credential ID and P-256 public key out of a WebAuthn attestation object.
    ///
    /// - Parameter data: The raw `attestationObject` CBOR bytes.
    /// - Returns: The extracted credential ID and public key.
    ///
    static func parseCredential(fromAttestationObject data: Data) throws -> ParsedCredential {
        let authData = try authenticatorData(fromAttestationObject: data)
        return try parseCredential(fromAuthenticatorData: authData)
    }

    // MARK: Private

    /// Locates and returns the `authData` byte string from the top-level attestation object map.
    private static func authenticatorData(fromAttestationObject data: Data) throws -> Data {
        var reader = CBORReader(data: data)
        guard case let .map(pairCount) = try reader.readHeader() else {
            throw ParsingError.malformedTopLevelCBOR
        }

        for _ in 0 ..< pairCount {
            let key = try reader.readTextString()
            if key == "authData" {
                return try reader.readByteString()
            }
            try reader.skipItem()
        }

        throw ParsingError.missingAuthData
    }

    /// Walks the fixed-layout prefix of `authData` to extract the credential ID and COSE key.
    private static func parseCredential(fromAuthenticatorData authData: Data) throws -> ParsedCredential {
        let bytes = [UInt8](authData)
        guard bytes.count >= 37 else { throw ParsingError.authDataTooShort }

        let flags = bytes[32]
        guard flags & 0x40 != 0 else { throw ParsingError.missingAttestedCredentialData }

        guard bytes.count >= 55 else { throw ParsingError.authDataTooShort }
        let credentialIdLength = Int(bytes[53]) << 8 | Int(bytes[54])

        let credentialIdStart = 55
        let credentialIdEnd = credentialIdStart + credentialIdLength
        guard bytes.count >= credentialIdEnd else { throw ParsingError.malformedCredentialIdLength }
        let credentialId = Data(bytes[credentialIdStart ..< credentialIdEnd])

        let coseKeyData = Data(bytes[credentialIdEnd...])
        let publicKeyX963 = try parseCOSEKey(from: coseKeyData)

        return ParsedCredential(credentialId: credentialId, publicKeyX963: publicKeyX963)
    }

    /// Parses an EC2/P-256/ES256 COSE_Key CBOR map into its X9.63 public key representation.
    private static func parseCOSEKey(from data: Data) throws -> Data {
        var reader = CBORReader(data: data)
        guard case let .map(pairCount) = try reader.readHeader() else {
            throw ParsingError.malformedCOSEKey
        }

        var keyType: Int?
        var algorithm: Int?
        var curve: Int?
        var xCoordinate: Data?
        var yCoordinate: Data?

        for _ in 0 ..< pairCount {
            let key = try reader.readInt()
            switch key {
            case 1:
                keyType = try reader.readInt()
            case 3:
                algorithm = try reader.readInt()
            case -1:
                curve = try reader.readInt()
            case -2:
                xCoordinate = try reader.readByteString()
            case -3:
                yCoordinate = try reader.readByteString()
            default:
                try reader.skipItem()
            }
        }

        guard let keyType, let algorithm, let curve, let xCoordinate, let yCoordinate else {
            throw ParsingError.malformedCOSEKey
        }
        guard keyType == 2 else { throw ParsingError.unsupportedKeyType(keyType) }
        guard algorithm == -7 else { throw ParsingError.unsupportedAlgorithm(algorithm) }
        guard curve == 1 else { throw ParsingError.unsupportedCurve(curve) }
        guard xCoordinate.count == 32, yCoordinate.count == 32 else { throw ParsingError.malformedCOSEKey }

        return Data([0x04]) + xCoordinate + yCoordinate
    }
}

// MARK: - CBORReader

/// A minimal, sequential CBOR item reader. Only understands the major types needed to walk a
/// WebAuthn attestation object and COSE key: unsigned/negative integers, byte strings, text
/// strings, arrays, and maps with definite-length headers.
private struct CBORReader {
    // MARK: Types

    /// A decoded CBOR item header: the major type plus its length or value.
    enum Header: Equatable {
        case unsignedInt(UInt64)
        case negativeInt(UInt64)
        case byteString(Int)
        case textString(Int)
        case array(Int)
        case map(Int)
    }

    // MARK: Private Properties

    private let bytes: [UInt8]
    private var offset = 0

    // MARK: Initialization

    init(data: Data) {
        bytes = [UInt8](data)
    }

    // MARK: Methods

    /// Reads and decodes the next CBOR item header, advancing past it.
    mutating func readHeader() throws -> Header {
        let initialByte = try readBytes(1)[0]
        let majorType = initialByte >> 5
        let additionalInfo = initialByte & 0x1F
        let value = try readAdditionalValue(additionalInfo)

        switch majorType {
        case 0: return .unsignedInt(value)
        case 1: return .negativeInt(value)
        case 2: return .byteString(Int(value))
        case 3: return .textString(Int(value))
        case 4: return .array(Int(value))
        case 5: return .map(Int(value))
        default: throw COSEKeyParser.ParsingError.malformedTopLevelCBOR
        }
    }

    /// Reads a byte string item, throwing if the next item is not a byte string.
    mutating func readByteString() throws -> Data {
        guard case let .byteString(length) = try readHeader() else {
            throw COSEKeyParser.ParsingError.malformedTopLevelCBOR
        }
        return try Data(readBytes(length))
    }

    /// Reads a UTF-8 text string item, throwing if the next item is not a text string.
    mutating func readTextString() throws -> String {
        guard case let .textString(length) = try readHeader() else {
            throw COSEKeyParser.ParsingError.malformedTopLevelCBOR
        }
        guard let string = try String(bytes: readBytes(length), encoding: .utf8) else {
            throw COSEKeyParser.ParsingError.malformedTopLevelCBOR
        }
        return string
    }

    /// Reads a signed integer item (positive or negative), throwing on any other type.
    mutating func readInt() throws -> Int {
        switch try readHeader() {
        case let .unsignedInt(value):
            return Int(value)
        case let .negativeInt(value):
            return -1 - Int(value)
        default:
            throw COSEKeyParser.ParsingError.malformedCOSEKey
        }
    }

    /// Reads and discards the next CBOR item, recursing into arrays/maps as needed.
    mutating func skipItem() throws {
        switch try readHeader() {
        case .negativeInt, .unsignedInt:
            break
        case let .byteString(length), let .textString(length):
            _ = try readBytes(length)
        case let .array(count):
            for _ in 0 ..< count {
                try skipItem()
            }
        case let .map(count):
            for _ in 0 ..< (count * 2) {
                try skipItem()
            }
        }
    }

    // MARK: Private

    /// Reads the additional-info-dependent length/value trailing an initial byte.
    private mutating func readAdditionalValue(_ additionalInfo: UInt8) throws -> UInt64 {
        switch additionalInfo {
        case 0 ... 23:
            return UInt64(additionalInfo)
        case 24:
            return try UInt64(readBytes(1)[0])
        case 25:
            return try readBytes(2).reduce(0) { $0 << 8 | UInt64($1) }
        case 26:
            return try readBytes(4).reduce(0) { $0 << 8 | UInt64($1) }
        default:
            throw COSEKeyParser.ParsingError.malformedTopLevelCBOR
        }
    }

    /// Reads `count` raw bytes, throwing rather than trapping if that would read out of bounds.
    private mutating func readBytes(_ count: Int) throws -> [UInt8] {
        guard count >= 0, offset + count <= bytes.count else {
            throw COSEKeyParser.ParsingError.malformedTopLevelCBOR
        }
        let slice = Array(bytes[offset ..< offset + count])
        offset += count
        return slice
    }
}
