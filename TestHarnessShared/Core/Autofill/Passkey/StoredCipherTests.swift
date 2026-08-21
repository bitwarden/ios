import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - StoredCipherTests

/// Tests for `StoredCipher`.
///
class StoredCipherTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(cipher:)` returns `nil` for a cipher with no login.
    func test_init_cipherWithoutLogin_returnsNil() {
        let cipher = Cipher(cipherView: .fixture(login: nil))
        XCTAssertNil(StoredCipher(cipher: cipher))
    }

    /// `init(cipher:)` returns `nil` for a login cipher with no Fido2 credential.
    func test_init_cipherWithoutFido2Credential_returnsNil() {
        let cipher = Cipher(cipherView: .fixture(login: .fixture(fido2Credentials: nil)))
        XCTAssertNil(StoredCipher(cipher: cipher))
    }

    /// `init(cipher:)` followed by `.cipher` round-trips back to an equal `Cipher`.
    func test_init_thenCipher_roundTrips() throws {
        let fido2Credential = Fido2Credential(fido2CredentialView: .fixture())
        let originalCipher = Cipher(cipherView: .fixture(
            id: "cipher-id",
            login: .fixture(fido2Credentials: [fido2Credential]),
            name: "Example",
        ))

        let storedCipher = try XCTUnwrap(StoredCipher(cipher: originalCipher))

        XCTAssertEqual(storedCipher.cipher, originalCipher)
    }

    /// An `StoredCipher` round-trips through JSON encoding/decoding unchanged.
    func test_codable_roundTrips() throws {
        let fido2Credential = Fido2Credential(fido2CredentialView: .fixture())
        let cipher = Cipher(cipherView: .fixture(login: .fixture(fido2Credentials: [fido2Credential])))
        let storedCipher = try XCTUnwrap(StoredCipher(cipher: cipher))

        let data = try JSONEncoder().encode(storedCipher)
        let decoded = try JSONDecoder().decode(StoredCipher.self, from: data)

        XCTAssertEqual(decoded, storedCipher)
    }
}
