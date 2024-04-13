import CryptoKit
import Foundation
import XCTest

@testable import AuthenticatorShared

// MARK: - CryptographyServiceTests

class CryptographyServiceTests: AuthenticatorTestCase {
    // MARK: Properties

    var keychainRepository: MockKeychainRepository!
    var subject: DefaultCryptographyService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        keychainRepository = MockKeychainRepository()

        subject = DefaultCryptographyService(
            cryptographyKeyService: CryptographyKeyService(
                keychainRepository: keychainRepository
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        keychainRepository = nil
        subject = nil
    }

    // MARK: Tests

    // swiftlint:disable line_length

    /// `encrypt(_:)` encrypts the TOTP key, and `decrypt(_:)` decrypts it
    func test_encrypt_decrypt() async throws {
        keychainRepository.getSecretKeyResult = .success(SymmetricKey(size: .bits256).base64EncodedString())

        let item = AuthenticatorItemView(
            id: "ID",
            name: "Name",
            totpKey: "otpauth://totp/ACME%20Co:john.doe@email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME%20Co&algorithm=SHA1&digits=6&period=30"
        )

        let encrypted = try await subject.encrypt(item)

        XCTAssertEqual(encrypted.id, item.id)
        XCTAssertEqual(encrypted.name, item.name)
        XCTAssertNotEqual(encrypted.totpKey, item.totpKey)

        let decrypted = try await subject.decrypt(encrypted)

        XCTAssertEqual(item, decrypted)
    }

    // swiftlint:enable line_length
}
