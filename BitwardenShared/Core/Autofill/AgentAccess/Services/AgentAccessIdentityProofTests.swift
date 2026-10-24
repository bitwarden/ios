import CryptoKit
import XCTest

@testable import BitwardenShared

class AgentAccessIdentityProofTests: BitwardenTestCase {
    // MARK: Test Vector

    static let userId = "11111111-2222-3333-4444-555555555555"

    static let fingerprint = "56475aa75463474c0285df5dbf2bcab73da651358839e9b77481b2eab107708c"

    static let publicKey = Data(hex: "03a107bff3ce10be1d70dd18e74bc09967e4d6309ba50d5f1ddc8664125531b8")

    /// The signature `ed25519-dalek` produced for the vector. CryptoKit signatures are randomized, so
    /// only verification of this value is deterministic.
    static let signature = Data(
        hex: "dcff0fc5231b11833d6d101ac907d667ca0e56ec0d535284175f4c24d89abb55"
            + "3b865d622223e88317c9e0e46e78238abc54bb157bade1911b1f9e5a858c100a",
    )

    /// The stored key for the seed `00 01 ... 1f`.
    static var identity: Data {
        storedKey(seed: Data((0 ..< 32).map { UInt8($0) }), publicKey: publicKey)
    }

    /// Asserts the proof carries the vector fingerprint and key and a valid signature for the user.
    static func assertValid(_ proof: AgentAccessIdentityProof?, file: StaticString = #filePath, line: UInt = #line) {
        guard let proof, let signature = Data(base64Encoded: proof.signature),
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: publicKey) else {
            return XCTFail("Missing or malformed proof", file: file, line: line)
        }
        XCTAssertEqual(proof.fingerprint, fingerprint, file: file, line: line)
        XCTAssertEqual(proof.publicKey, publicKey.base64EncodedString(), file: file, line: line)
        XCTAssertEqual(signature.count, 64, file: file, line: line)
        XCTAssertTrue(
            key.isValidSignature(signature, for: AgentAccessIdentityProof.message(userId: userId)),
            file: file,
            line: line,
        )
    }

    static func storedKey(seed: Data, publicKey: Data, alg: UInt8 = 0x27) -> Data {
        var bytes: [UInt8] = [0xA5, 0x01, 0x01, 0x03, alg, 0x20, 0x06]
        bytes += [0x21, 0x58, 0x20] + [UInt8](publicKey)
        bytes += [0x23, 0x58, 0x20] + [UInt8](seed)
        return Data(bytes)
    }

    // MARK: Tests

    /// `make` produces a valid signature over the registration message for the vector key.
    func test_make() throws {
        let proof = try AgentAccessIdentityProof.make(
            identity: Self.identity,
            fingerprint: Self.fingerprint,
            userId: Self.userId,
        )

        Self.assertValid(proof)
    }

    /// The `ed25519-dalek` signature the server tests against verifies for the same message.
    func test_message_verifiesRustSignature() throws {
        let key = try Curve25519.Signing.PublicKey(rawRepresentation: Self.publicKey)

        XCTAssertTrue(key.isValidSignature(Self.signature, for: AgentAccessIdentityProof.message(userId: Self.userId)))
    }

    /// `make` signs the message for the lowercase user ID.
    func test_make_signsLowercaseUserId() throws {
        let proof = try AgentAccessIdentityProof.make(
            identity: Self.identity,
            fingerprint: Self.fingerprint,
            userId: Self.userId.uppercased(),
        )

        let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: Self.publicKey)
        let signature = try XCTUnwrap(Data(base64Encoded: proof.signature))
        XCTAssertTrue(publicKey.isValidSignature(signature, for: AgentAccessIdentityProof.message(userId: Self.userId)))
    }

    /// `make` throws for bytes that are not a key map.
    func test_make_invalidIdentity() {
        XCTAssertThrowsError(
            try AgentAccessIdentityProof.make(identity: Data([1, 2, 3]), fingerprint: Self.fingerprint, userId: "1"),
        ) { XCTAssertEqual($0 as? AgentAccessIdentityProofError, .invalidIdentity) }
        XCTAssertThrowsError(
            try AgentAccessIdentityProof.make(identity: Data(), fingerprint: Self.fingerprint, userId: "1"),
        ) { XCTAssertEqual($0 as? AgentAccessIdentityProofError, .invalidIdentity) }
    }

    /// `make` throws for a key that is not EdDSA.
    func test_make_wrongAlgorithm() {
        let identity = Self.storedKey(seed: Data(repeating: 0, count: 32), publicKey: Self.publicKey, alg: 0x26)

        XCTAssertThrowsError(
            try AgentAccessIdentityProof.make(identity: identity, fingerprint: Self.fingerprint, userId: "1"),
        ) { XCTAssertEqual($0 as? AgentAccessIdentityProofError, .invalidIdentity) }
    }

    /// `make` throws when the public key does not belong to the seed.
    func test_make_seedMismatch() {
        let identity = Self.storedKey(seed: Data(repeating: 7, count: 32), publicKey: Self.publicKey)

        XCTAssertThrowsError(
            try AgentAccessIdentityProof.make(identity: identity, fingerprint: Self.fingerprint, userId: "1"),
        ) { XCTAssertEqual($0 as? AgentAccessIdentityProofError, .invalidIdentity) }
    }

    /// `make` throws when the key does not hash to the fingerprint.
    func test_make_fingerprintMismatch() {
        XCTAssertThrowsError(
            try AgentAccessIdentityProof.make(
                identity: Self.identity,
                fingerprint: String(repeating: "ab", count: 32),
                userId: "1",
            ),
        ) { XCTAssertEqual($0 as? AgentAccessIdentityProofError, .fingerprintMismatch) }
    }
}

private extension Data {
    init(hex: String) {
        var data = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            data.append(UInt8(hex[index ..< next], radix: 16)!)
            index = next
        }
        self = data
    }
}
