// swiftlint:disable:this file_name

import BitwardenKit
import XCTest

@testable import BitwardenShared

// MARK: - KeychainRepositoryDeviceAuthTests

final class KeychainRepositoryDeviceAuthTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var keychainService: MockKeychainService!
    var subject: DefaultKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        keychainService = MockKeychainService()
        subject = DefaultKeychainRepository(
            appIdService: AppIdService(
                appSettingStore: appSettingsStore,
            ),
            keychainService: keychainService,
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        keychainService = nil
        subject = nil
    }

    // MARK: Tests - Device Auth Key

    /// `deleteDeviceAuthKey(userId:)` deletes the device auth key and metadata from the keychain.
    ///
    func test_deleteDeviceAuthKey() async throws {
        try await subject.deleteDeviceAuthKey(userId: "1")

        XCTAssertEqual(keychainService.deleteQueries.count, 2)

        let metadataQuery = keychainService.deleteQueries[0] as NSDictionary
        let metadataAccount = metadataQuery[kSecAttrAccount] as? String
        let metadataKey = await subject.formattedKey(for: .deviceAuthKeyMetadata(userId: "1"))
        XCTAssertEqual(metadataAccount, metadataKey)

        let recordQuery = keychainService.deleteQueries[1] as NSDictionary
        let recordAccount = recordQuery[kSecAttrAccount] as? String
        let recordKey = await subject.formattedKey(for: .deviceAuthKey(userId: "1"))
        XCTAssertEqual(recordAccount, recordKey)
    }

    /// `deleteDeviceAuthKey(userId:)` throws an error if one occurs.
    ///
    func test_deleteDeviceAuthKey_error() async {
        let error = KeychainServiceError.osStatusError(-1)
        keychainService.deleteResult = .failure(error)
        await assertAsyncThrows(error: error) {
            try await subject.deleteDeviceAuthKey(userId: "1")
        }
    }

    /// `getDeviceAuthKey(userId:)` returns the stored device auth key.
    ///
    func test_getDeviceAuthKey() async throws {
        let record = DeviceAuthKeyRecord.fixture()

        let recordData = try JSONEncoder.defaultEncoder.encode(record)
        let recordString = String(data: recordData, encoding: .utf8)!

        keychainService.setSearchResultData(string: recordString)
        let result = try await subject.getDeviceAuthKey(userId: "1")

        XCTAssertEqual(result, record)
    }

    /// `getDeviceAuthKey(userId:)` returns nil if the key is not found.
    ///
    func test_getDeviceAuthKey_notFound() async throws {
        let error = KeychainServiceError.keyNotFound(KeychainItem.deviceAuthKey(userId: "1"))
        keychainService.searchResult = .failure(error)

        let result = try await subject.getDeviceAuthKey(userId: "1")

        XCTAssertNil(result)
    }

    /// `getDeviceAuthKey(userId:)` returns nil if the key is not found.
    ///
    func test_getDeviceAuthKey_notFound_osStatus() async throws {
        let error = KeychainServiceError.osStatusError(errSecItemNotFound)
        keychainService.searchResult = .failure(error)

        let result = try await subject.getDeviceAuthKey(userId: "1")

        XCTAssertNil(result)
    }

    /// `getDeviceAuthKey(userId:)` throws an error if the data is invalid.
    ///
    func test_getDeviceAuthKey_invalidData() async throws {
        keychainService.setSearchResultData(string: "invalid-json")

        await assertAsyncThrows {
            _ = try await subject.getDeviceAuthKey(userId: "1")
        }
    }

    /// `getDeviceAuthKeyMetadata(userId:)` returns the stored device auth key metadata.
    ///
    func test_getDeviceAuthKeyMetadata() async throws {
        let metadata = DeviceAuthKeyMetadata.fixture()
        let metadataData = try JSONEncoder.defaultEncoder.encode(metadata)
        let metadataString = String(data: metadataData, encoding: .utf8)!

        keychainService.setSearchResultData(string: metadataString)
        let result = try await subject.getDeviceAuthKeyMetadata(userId: "1")

        XCTAssertEqual(result, metadata)
    }

    /// `getDeviceAuthKeyMetadata(userId:)` returns nil if the metadata is not found.
    ///
    func test_getDeviceAuthKeyMetadata_notFound() async throws {
        let error = KeychainServiceError.keyNotFound(KeychainItem.deviceAuthKeyMetadata(userId: "1"))
        keychainService.searchResult = .failure(error)

        let result = try await subject.getDeviceAuthKeyMetadata(userId: "1")

        XCTAssertNil(result)
    }

    /// `getDeviceAuthKeyMetadata(userId:)` returns nil if the metadata is not found.
    ///
    func test_getDeviceAuthKeyMetadata_notFound_osStatus() async throws {
        let error = KeychainServiceError.osStatusError(errSecItemNotFound)
        keychainService.searchResult = .failure(error)

        let result = try await subject.getDeviceAuthKeyMetadata(userId: "1")

        XCTAssertNil(result)
    }

    /// `getDeviceAuthKeyMetadata(userId:)` throws an error if the data is invalid.
    ///
    func test_getDeviceAuthKeyMetadata_invalidData() async throws {
        keychainService.setSearchResultData(string: "invalid-json")

        await assertAsyncThrows {
            _ = try await subject.getDeviceAuthKeyMetadata(userId: "1")
        }
    }

    /// `setDeviceAuthKey(record:metadata:userId:)` stores the device auth key and metadata in the keychain.
    ///
    func test_setDeviceAuthKey() async throws {
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [],
                nil,
            )!,
        )

        let record = DeviceAuthKeyRecord.fixture()
        let metadata = DeviceAuthKeyMetadata.fixture()

        try await subject.setDeviceAuthKey(record: record, metadata: metadata, userId: "1")

        // Verify the record was stored
        XCTAssertEqual(keychainService.addCalls.count, 2)
        let recordAttributes = try XCTUnwrap(keychainService.addCalls[0]) as Dictionary
        let recordData = try XCTUnwrap(recordAttributes[kSecValueData] as? Data)
        let decodedRecord = try JSONDecoder.defaultDecoder.decode(
            DeviceAuthKeyRecord.self,
            from: recordData,
        )
        XCTAssertEqual(decodedRecord, record)

        // Verify the metadata was stored
        let metadataAttributes = try XCTUnwrap(keychainService.addCalls[1]) as Dictionary
        let metadataData = try XCTUnwrap(metadataAttributes[kSecValueData] as? Data)
        let decodedMetadata = try JSONDecoder.defaultDecoder.decode(
            DeviceAuthKeyMetadata.self,
            from: metadataData,
        )
        XCTAssertEqual(decodedMetadata, metadata)
    }

    /// `setDeviceAuthKey(record:metadata:userId:)` throws an error if one occurs.
    ///
    func test_setDeviceAuthKey_accessControlError() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainService.accessControlResult = .failure(error)

        let record = DeviceAuthKeyRecord.fixture()
        let metadata = DeviceAuthKeyMetadata.fixture()

        await assertAsyncThrows(error: error) {
            try await subject.setDeviceAuthKey(record: record, metadata: metadata, userId: "1")
        }
    }
}
