import CryptoKit
import Foundation
import XCTest

@testable import AuthenticatorBridgeKit

final class AuthenticatorCryptographyServiceTests: AuthenticatorBridgeKitTestCase {
    // MARK: Properties

    let items: [AuthenticatorBridgeItemDataModel] = AuthenticatorBridgeItemDataModel.fixtures()
    var sharedKeychainRepository: MockSharedKeychainRepository!
    var subject: AuthenticatorCryptographyService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        sharedKeychainRepository = MockSharedKeychainRepository()
        sharedKeychainRepository.authenticatorKey = sharedKeychainRepository.generateKeyData()
        subject = DefaultAuthenticatorCryptographyService(
            sharedKeychainRepository: sharedKeychainRepository
        )
    }

    override func tearDown() {
        sharedKeychainRepository = nil
        subject = nil
        super.tearDown()
    }

    // MARK: Tests

    /// Verify that `AuthenticatorCryptographyService.decryptAuthenticatorItems(:)` correctly
    /// decrypts an encrypted array of `AuthenticatorBridgeItemDataModel`.
    ///
    func test_decryptAuthenticatorItems_success() async throws {
        let encryptedItems = try await subject.encryptAuthenticatorItems(items)
        let decryptedItems = try await subject.decryptAuthenticatorItems(encryptedItems)

        XCTAssertEqual(items, decryptedItems)
    }

    /// Verify that `AuthenticatorCryptographyService.encryptAuthenticatorItems()' throws
    /// when the `SharedKeyRepository` authenticator key is missing.
    ///
    func test_decryptAuthenticatorItems_throwsKeyMissingError() async throws {
        let error = AuthenticatorKeychainServiceError.keyNotFound(SharedKeychainItem.authenticatorKey)

        try sharedKeychainRepository.deleteAuthenticatorKey()
        await assertAsyncThrows(error: error) {
            _ = try await subject.decryptAuthenticatorItems(items)
        }
    }

    /// Verify that `AuthenticatorCryptographyService.encryptAuthenticatorItems(:)` correctly
    /// encrypts an array of `AuthenticatorBridgeItemDataModel`.
    ///
    func test_encryptAuthenticatorItems_success() async throws {
        let encryptedItems = try await subject.encryptAuthenticatorItems(items)

        XCTAssertEqual(items.count, encryptedItems.count)

        for index in 0 ..< items.count {
            let item = try XCTUnwrap(items[index])
            let encryptedItem = try XCTUnwrap(encryptedItems[index])

            // Unencrypted values remain equal
            XCTAssertEqual(item.favorite, encryptedItem.favorite)
            XCTAssertEqual(item.id, encryptedItem.id)
            XCTAssertEqual(item.name, encryptedItem.name)

            // Encrypted values should not remain equal, unless they were `nil`
            if item.totpKey != nil {
                XCTAssertNotEqual(item.totpKey, encryptedItem.totpKey)
            } else {
                XCTAssertNil(encryptedItem.totpKey)
            }
            if item.username != nil {
                XCTAssertNotEqual(item.username, encryptedItem.username)
            } else {
                XCTAssertNil(encryptedItem.username)
            }
        }
    }

    /// Verify that `AuthenticatorCryptographyService.encryptAuthenticatorItems()' throws
    /// when the `SharedKeyRepository` authenticator key is missing.
    ///
    func test_encryptAuthenticatorItems_throwsKeyMissingError() async throws {
        let error = AuthenticatorKeychainServiceError.keyNotFound(SharedKeychainItem.authenticatorKey)

        try sharedKeychainRepository.deleteAuthenticatorKey()
        await assertAsyncThrows(error: error) {
            _ = try await subject.encryptAuthenticatorItems(items)
        }
    }
}
