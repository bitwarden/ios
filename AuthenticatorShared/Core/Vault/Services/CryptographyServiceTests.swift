import CryptoKit
import Foundation
import XCTest

@testable import AuthenticatorShared

// MARK: - CryptographyServiceTests

class CryptographyServiceTests: AuthenticatorTestCase {
    // MARK: Properties

    var stateService: MockStateService!
    var subject: DefaultCryptographyService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stateService = MockStateService()

        subject = DefaultCryptographyService(
            cryptographyKeyService: CryptographyKeyService(
                stateService: stateService
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        stateService = nil
        subject = nil
    }

    // MARK: Tests

    // swiftlint:disable line_length

    /// `decrypt(_:)` handles empty fields
    func test_decrypt_empty_name() async throws {
        stateService.getSecretKeyResult = .success(SymmetricKey(size: .bits256).base64EncodedString())

        let item = AuthenticatorItem(
            favorite: false,
            id: "ID",
            name: "",
            totpKey: "",
            username: ""
        )

        let decrypted = try await subject.decrypt(item)

        XCTAssertEqual(decrypted.name, "")
        XCTAssertNil(decrypted.totpKey)
        XCTAssertNil(decrypted.username)
    }

    /// `encrypt(_:)` encrypts the TOTP key, and `decrypt(_:)` decrypts it
    func test_encrypt_decrypt() async throws {
        stateService.getSecretKeyResult = .success(SymmetricKey(size: .bits256).base64EncodedString())

        let item = AuthenticatorItemView(
            favorite: false,
            id: "ID",
            name: "Name",
            totpKey: "otpauth://totp/ACME%20Co:john.doe@email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME%20Co&algorithm=SHA1&digits=6&period=30",
            username: "john.doe@email.com"
        )

        let encrypted = try await subject.encrypt(item)

        XCTAssertEqual(encrypted.favorite, item.favorite)
        XCTAssertEqual(encrypted.id, item.id)
        XCTAssertNotEqual(encrypted.name, item.name)
        XCTAssertNotEqual(encrypted.totpKey, item.totpKey)
        XCTAssertNotEqual(encrypted.username, item.username)

        let decrypted = try await subject.decrypt(encrypted)

        XCTAssertEqual(item, decrypted)
    }

    /// `encrypt(_:)` and `decrypt(_:)` handle nil fields
    func test_encrypt_decrypt_nil() async throws {
        stateService.getSecretKeyResult = .success(SymmetricKey(size: .bits256).base64EncodedString())

        let item = AuthenticatorItemView(
            favorite: false,
            id: "ID",
            name: "Name",
            totpKey: nil,
            username: nil
        )

        let encrypted = try await subject.encrypt(item)

        XCTAssertEqual(encrypted.favorite, item.favorite)
        XCTAssertEqual(encrypted.id, item.id)
        XCTAssertNotEqual(encrypted.name, item.name)
        XCTAssertNil(encrypted.totpKey)
        XCTAssertNil(encrypted.username)

        let decrypted = try await subject.decrypt(encrypted)

        XCTAssertEqual(item, decrypted)
    }

    /// `encrypt(_:)` handles an empty name
    func test_encrypt_emptyName() async throws {
        stateService.getSecretKeyResult = .success(SymmetricKey(size: .bits256).base64EncodedString())

        let item = AuthenticatorItemView(
            favorite: false,
            id: "ID",
            name: "",
            totpKey: nil,
            username: nil
        )

        let encrypted = try await subject.encrypt(item)

        XCTAssertEqual(encrypted.favorite, item.favorite)
        XCTAssertEqual(encrypted.id, item.id)
        XCTAssertNotEqual(encrypted.name, item.name)
        XCTAssertNil(encrypted.totpKey)
        XCTAssertNil(encrypted.username)

        let decrypted = try await subject.decrypt(encrypted)

        XCTAssertEqual(item, decrypted)
    }

    // swiftlint:enable line_length
}
