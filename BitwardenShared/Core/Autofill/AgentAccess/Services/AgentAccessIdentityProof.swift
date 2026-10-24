import CryptoKit
import Foundation

// MARK: - AgentAccessIdentityProofError

/// Errors thrown while building a proof of possession of the Agent Access identity.
///
enum AgentAccessIdentityProofError: Error, Equatable {
    /// The stored identity is not an Ed25519 key map with a seed and public key.
    case invalidIdentity

    /// The stored identity does not match the fingerprint.
    case fingerprintMismatch
}

// MARK: - AgentAccessIdentityProof

/// The proof of possession the server requires to register an identity fingerprint.
///
struct AgentAccessIdentityProof: Equatable {
    // MARK: Properties

    /// The 64 character lowercase hex identity fingerprint.
    let fingerprint: String

    /// The base64 raw Ed25519 public key.
    let publicKey: String

    /// The base64 Ed25519 signature over the registration message for the user.
    let signature: String

    // MARK: Static Methods

    /// The bytes the identity key signs to register for a user.
    static func message(userId: String) -> Data {
        Data("bitwarden-agent-access-register-v1:\(userId.lowercased())".utf8)
    }

    /// Builds the proof from the key the SDK stores for the identity.
    ///
    /// - Parameters:
    ///   - identity: The stored key bytes of the identity.
    ///   - fingerprint: The fingerprint reported by the SDK for the identity.
    ///   - userId: The ID of the user registering the identity.
    /// - Returns: The proof.
    ///
    static func make(identity: Data, fingerprint: String, userId: String) throws -> AgentAccessIdentityProof {
        guard let key = StoredEd25519Key(identity), key.seed.count == 32, key.publicKey.count == 32 else {
            throw AgentAccessIdentityProofError.invalidIdentity
        }
        let digest = SHA256.hash(data: key.publicKey).map { String(format: "%02x", $0) }.joined()
        guard digest == fingerprint else { throw AgentAccessIdentityProofError.fingerprintMismatch }

        let privateKey: Curve25519.Signing.PrivateKey
        do {
            privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: key.seed)
        } catch {
            throw AgentAccessIdentityProofError.invalidIdentity
        }
        guard privateKey.publicKey.rawRepresentation == key.publicKey else {
            throw AgentAccessIdentityProofError.invalidIdentity
        }
        let signature = try privateKey.signature(for: message(userId: userId))
        return AgentAccessIdentityProof(
            fingerprint: fingerprint,
            publicKey: key.publicKey.base64EncodedString(),
            signature: signature.base64EncodedString(),
        )
    }
}

// MARK: - StoredEd25519Key

/// The parts of an Ed25519 key map (RFC 9052) the proof needs.
///
private struct StoredEd25519Key {
    /// The 32 byte private seed (`d`, key -4).
    let seed: Data

    /// The 32 byte public key (`x`, key -2).
    let publicKey: Data

    /// Decodes the key map. Returns `nil` unless it is an OKP Ed25519 key with `alg` EdDSA.
    init?(_ data: Data) {
        var reader = CborReader(bytes: [UInt8](data))
        guard let count = reader.mapCount() else { return nil }
        var integers: [Int: Int] = [:]
        var byteStrings: [Int: Data] = [:]
        for _ in 0 ..< count {
            guard let key = reader.integer(), let value = reader.value() else { return nil }
            switch value {
            case let .integer(number):
                integers[key] = number
            case let .bytes(bytes):
                byteStrings[key] = bytes
            case .other:
                break
            }
        }
        guard integers[1] == 1, integers[3] == -8, integers[-1] == 6,
              let publicKey = byteStrings[-2], let seed = byteStrings[-4] else { return nil }
        self.publicKey = publicKey
        self.seed = seed
    }
}

// MARK: - CborReader

/// A minimal CBOR reader for definite length maps of integers, byte strings and text strings.
///
private struct CborReader {
    enum Value {
        case integer(Int)
        case bytes(Data)
        case other
    }

    let bytes: [UInt8]
    var offset = 0

    /// Reads the head byte and its argument.
    private mutating func head() -> (major: UInt8, argument: Int)? {
        guard offset < bytes.count else { return nil }
        let initial = bytes[offset]
        offset += 1
        let major = initial >> 5
        let info = Int(initial & 0x1F)
        switch info {
        case 0 ..< 24:
            return (major, info)
        case 24 ... 27:
            let length = 1 << (info - 24)
            guard offset + length <= bytes.count, length <= 4 else { return nil }
            let argument = bytes[offset ..< offset + length].reduce(0) { ($0 << 8) | Int($1) }
            offset += length
            return (major, argument)
        default:
            return nil
        }
    }

    mutating func mapCount() -> Int? {
        guard let (major, argument) = head(), major == 5 else { return nil }
        return argument
    }

    mutating func integer() -> Int? {
        guard let (major, argument) = head() else { return nil }
        switch major {
        case 0: return argument
        case 1: return -1 - argument
        default: return nil
        }
    }

    mutating func value() -> Value? {
        guard let (major, argument) = head() else { return nil }
        switch major {
        case 0:
            return .integer(argument)
        case 1:
            return .integer(-1 - argument)
        case 2, 3:
            guard offset + argument <= bytes.count else { return nil }
            defer { offset += argument }
            return major == 2 ? .bytes(Data(bytes[offset ..< offset + argument])) : .other
        default:
            return nil
        }
    }
}
