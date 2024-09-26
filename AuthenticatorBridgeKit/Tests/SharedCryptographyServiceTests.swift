import CryptoKit
import Foundation
import XCTest

@testable import AuthenticatorBridgeKit

final class SharedCryptographyServiceTests: AuthenticatorBridgeKitTestCase {
    // MARK: Properties

    let items: [AuthenticatorBridgeItemDataView] = AuthenticatorBridgeItemDataView.fixtures()
    var sharedKeychainRepository: MockSharedKeychainRepository!
    var subject: SharedCryptographyService!

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

    /// Verify that `SharedCryptographyService.decryptAuthenticatorItemDatas(:)` correctly
    /// decrypts an encrypted array of `AuthenticatorBridgeItemDataModel`.
    ///
    func test_decryptAuthenticatorItemDatas_success() async throws {
        let sharedDataStore = AuthenticatorBridgeDataStore(
            errorReporter: MockErrorReporter(),
            groupIdentifier: "com.example.bitwarden-authenticator",
            storeType: .memory
        )
        let encryptedItems = try await subject.encryptAuthenticatorItems(items)
        let decryptedItems = try await subject.decryptAuthenticatorItemDatas(
            encryptedItems.compactMap { item in
                try? AuthenticatorBridgeItemData(
                    context: sharedDataStore.persistentContainer.viewContext,
                    userId: "userId",
                    authenticatorItem: item
                )
            }
        )

        XCTAssertEqual(items, decryptedItems)
    }

    /// Verify that `SharedCryptographyService.decryptAuthenticatorItemDatas()' throws
    /// when the `SharedKeyRepository` authenticator key is missing.
    ///
    func test_decryptAuthenticatorItemDatas_throwsKeyMissingError() async throws {
        let error = AuthenticatorKeychainServiceError.keyNotFound(SharedKeychainItem.authenticatorKey)

        try sharedKeychainRepository.deleteAuthenticatorKey()
        await assertAsyncThrows(error: error) {
            _ = try await subject.decryptAuthenticatorItemDatas([])
        }
    }

    /// Verify that `SharedCryptographyService.decryptAuthenticatorItemModels(:)` correctly
    /// decrypts an encrypted array of `AuthenticatorBridgeItemDataModel`.
    ///
    func test_decryptAuthenticatorItemModels_success() async throws {
        let encryptedItems = try await subject.encryptAuthenticatorItems(items)
        let decryptedItems = try await subject.decryptAuthenticatorItemModels(encryptedItems)

        XCTAssertEqual(items, decryptedItems)
    }

    /// Verify that `SharedCryptographyService.decryptAuthenticatorItemModels()' throws
    /// when the `SharedKeyRepository` authenticator key is missing.
    ///
    func test_decryptAuthenticatorItemModels_throwsKeyMissingError() async throws {
        let error = AuthenticatorKeychainServiceError.keyNotFound(SharedKeychainItem.authenticatorKey)

        try sharedKeychainRepository.deleteAuthenticatorKey()
        await assertAsyncThrows(error: error) {
            _ = try await subject.decryptAuthenticatorItemModels([])
        }
    }

    /// Verify that `SharedCryptographyService.encryptAuthenticatorItems(:)` correctly
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

            // Encrypted values should not remain equal, unless they were `nil`
            XCTAssertNotEqual(item.name, encryptedItem.name)
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

    /// Verify that `SharedCryptographyService.encryptAuthenticatorItems()' throws
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
