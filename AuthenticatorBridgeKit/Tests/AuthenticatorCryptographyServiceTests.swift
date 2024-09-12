import CryptoKit
import Foundation
import XCTest

@testable import AuthenticatorBridgeKit

final class AuthenticatorCryptographyServiceTests: XCTestCase {
    // MARK: Properties

    let items: [AuthenticatorBridgeItemDataModel] = AuthenticatorBridgeItemDataModel.fixtures()
    var sharedKeychainRepository: MockSharedKeychainRepository!
    var subject: AuthenticatorCryptographyService!

    // MARK: Setup & Teardown

    override func setUp() {
        sharedKeychainRepository = MockSharedKeychainRepository()
        sharedKeychainRepository.authenticatorKey = sharedKeychainRepository.generateKeyData()
        subject = DefaultAuthenticatorCryptographyService(
            sharedKeychainRepository: sharedKeychainRepository
        )
    }

    override func tearDown() {
        sharedKeychainRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// Verify that `AuthenticatorCryptographyService.decryptAuthenticatorItems(:)` correctly
    /// decrypts an encrypted array of `AuthenticatorBridgeItemDataModel`.
    ///
    func testDecrypt() async throws {
        let encrytpedItems = try await subject.encryptAuthenticatorItems(items)
        let decrytpedItems = try await subject.decryptAuthenticatorItems(encrytpedItems)

        XCTAssertEqual(items, decrytpedItems)
    }

    /// Verify that `AuthenticatorCryptographyService.encryptAuthenticatorItems(:)` correctly
    /// encrypts an array of `AuthenticatorBridgeItemDataModel`.
    ///
    func testEncrypt() async throws {
        let encrytpedItems = try await subject.encryptAuthenticatorItems(items)

        XCTAssertEqual(items.count, encrytpedItems.count)

        for index in 0 ..< items.count {
            let item = try XCTUnwrap(items[index])
            let encrytpedItem = try XCTUnwrap(encrytpedItems[index])

            // Unencrypted values remain equal
            XCTAssertEqual(item.favorite, encrytpedItem.favorite)
            XCTAssertEqual(item.id, encrytpedItem.id)
            XCTAssertEqual(item.name, encrytpedItem.name)

            // Encrypted values should not remain equal, unless they were `nil`
            if item.totpKey != nil {
                XCTAssertNotEqual(item.totpKey, encrytpedItem.totpKey)
            } else {
                XCTAssertNil(encrytpedItem.totpKey)
            }
            if item.username != nil {
                XCTAssertNotEqual(item.username, encrytpedItem.username)
            } else {
                XCTAssertNil(encrytpedItem.username)
            }
        }
    }

    /// Verify that `AuthenticatorCryptographyService' throws when the `SharedKeyRrepository`
    /// authenticator key is missing.
    ///
    func testEncryptAndDecryptThrowWhenKeyMissing() async throws {
        try sharedKeychainRepository.deleteAuthenticatorKey()

        do {
            _ = try await subject.encryptAuthenticatorItems(items)
            XCTFail("AuthenticatorKeychainServiceError.keyNotFound should have been thrown")
        } catch AuthenticatorKeychainServiceError.keyNotFound(_) {}

        do {
            _ = try await subject.decryptAuthenticatorItems(items)
            XCTFail("AuthenticatorKeychainServiceError.keyNotFound should have been thrown")
        } catch AuthenticatorKeychainServiceError.keyNotFound(_) {}
    }
}
