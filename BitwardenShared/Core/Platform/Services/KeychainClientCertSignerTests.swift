import BitwardenSdk
import Foundation
import Security
import Testing

@testable import BitwardenShared

// MARK: - KeychainClientCertSignerTests

struct KeychainClientCertSignerTests {
    // MARK: Tests - schemes()

    /// `schemes()` returns the six RSA schemes for an RSA 2048 key.
    @Test
    func schemes_rsa() throws {
        let subject = try KeychainClientCertSigner(privateKey: makeKey(kSecAttrKeyTypeRSA, 2048))

        #expect(Set(subject.schemes()) == [
            .rsaPssSha512,
            .rsaPssSha384,
            .rsaPssSha256,
            .rsaPkcs1Sha512,
            .rsaPkcs1Sha384,
            .rsaPkcs1Sha256,
        ])
    }

    /// `schemes()` returns the ECDSA scheme for the key's curve, and nothing for P-521, which has no
    /// `TlsSigScheme`.
    @Test(arguments: [
        (256, [TlsSigScheme.ecdsaP256Sha256]),
        (384, [.ecdsaP384Sha384]),
        (521, []),
    ])
    func schemes_ec(bits: Int, expected: [TlsSigScheme]) throws {
        let subject = try KeychainClientCertSigner(privateKey: makeKey(kSecAttrKeyTypeECSECPrimeRandom, bits))

        #expect(subject.schemes() == expected)
    }

    // MARK: Private

    /// Creates an in-memory private key.
    private func makeKey(_ type: CFString, _ bits: Int) throws -> SecKey {
        let attributes: [CFString: Any] = [kSecAttrKeyType: type, kSecAttrKeySizeInBits: bits]
        return try #require(SecKeyCreateRandomKey(attributes as CFDictionary, nil))
    }
}
