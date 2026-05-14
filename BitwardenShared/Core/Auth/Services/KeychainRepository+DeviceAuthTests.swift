// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - KeychainRepositoryDeviceAuthTests

final class KeychainRepositoryDeviceAuthTests: BitwardenTestCase {
    // MARK: Properties

    var keychainServiceFacade: MockKeychainServiceFacade!
    var subject: DefaultKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        keychainServiceFacade = MockKeychainServiceFacade()
        subject = DefaultKeychainRepository(
            keychainService: MockKeychainService(),
            keychainServiceFacade: keychainServiceFacade,
        )
    }

    override func tearDown() {
        super.tearDown()

        keychainServiceFacade = nil
        subject = nil
    }

    // MARK: Tests - Device Auth Key

    /// `deleteDeviceAuthKey(userId:)` deletes metadata first, then the auth key, via the facade.
    ///
    func test_deleteDeviceAuthKey() async throws {
        var deletedKeys: [String] = []
        keychainServiceFacade.deleteValueClosure = { item in
            deletedKeys.append(item.unformattedKey)
        }

        try await subject.deleteDeviceAuthKey(userId: "1")

        XCTAssertEqual(deletedKeys.count, 2)
        XCTAssertEqual(deletedKeys[0], BitwardenKeychainItem.deviceAuthKeyMetadata(userId: "1").unformattedKey)
        XCTAssertEqual(deletedKeys[1], BitwardenKeychainItem.deviceAuthKey(userId: "1").unformattedKey)
    }

    /// `deleteDeviceAuthKey(userId:)` rethrows errors from the facade.
    ///
    func test_deleteDeviceAuthKey_error() async {
        let error = KeychainServiceError.osStatusError(-1)
        keychainServiceFacade.deleteValueThrowableError = error

        await assertAsyncThrows(error: error) {
            try await subject.deleteDeviceAuthKey(userId: "1")
        }
    }

    /// `getDeviceAuthKey(userId:)` returns the stored device auth key.
    ///
    func test_getDeviceAuthKey() async throws {
        let record = DeviceAuthKeyRecord.fixture()
        let recordData = try JSONEncoder.defaultEncoder.encode(record)
        keychainServiceFacade.getValueReturnValue = String(data: recordData, encoding: .utf8)!

        let result = try await subject.getDeviceAuthKey(userId: "1")

        XCTAssertEqual(result, record)
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.deviceAuthKey(userId: "1").unformattedKey,
        )
    }

    /// `getDeviceAuthKey(userId:)` returns nil when the key is not found.
    ///
    func test_getDeviceAuthKey_notFound() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            BitwardenKeychainItem.deviceAuthKey(userId: "1"),
        )

        let result = try await subject.getDeviceAuthKey(userId: "1")

        XCTAssertNil(result)
    }

    /// `getDeviceAuthKey(userId:)` returns nil when the OS status indicates not found.
    ///
    func test_getDeviceAuthKey_notFound_osStatus() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        let result = try await subject.getDeviceAuthKey(userId: "1")

        XCTAssertNil(result)
    }

    /// `getDeviceAuthKey(userId:)` rethrows when the stored data is invalid JSON.
    ///
    func test_getDeviceAuthKey_invalidData() async {
        keychainServiceFacade.getValueReturnValue = "invalid-json"

        await assertAsyncThrows {
            _ = try await subject.getDeviceAuthKey(userId: "1")
        }
    }

    /// `getDeviceAuthKeyMetadata(userId:)` returns the stored device auth key metadata.
    ///
    func test_getDeviceAuthKeyMetadata() async throws {
        let metadata = DeviceAuthKeyMetadata.fixture()
        let metadataData = try JSONEncoder.defaultEncoder.encode(metadata)
        keychainServiceFacade.getValueReturnValue = String(data: metadataData, encoding: .utf8)!

        let result = try await subject.getDeviceAuthKeyMetadata(userId: "1")

        XCTAssertEqual(result, metadata)
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.deviceAuthKeyMetadata(userId: "1").unformattedKey,
        )
    }

    /// `getDeviceAuthKeyMetadata(userId:)` returns nil when the metadata is not found.
    ///
    func test_getDeviceAuthKeyMetadata_notFound() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            BitwardenKeychainItem.deviceAuthKeyMetadata(userId: "1"),
        )

        let result = try await subject.getDeviceAuthKeyMetadata(userId: "1")

        XCTAssertNil(result)
    }

    /// `getDeviceAuthKeyMetadata(userId:)` returns nil when the OS status indicates not found.
    ///
    func test_getDeviceAuthKeyMetadata_notFound_osStatus() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        let result = try await subject.getDeviceAuthKeyMetadata(userId: "1")

        XCTAssertNil(result)
    }

    /// `getDeviceAuthKeyMetadata(userId:)` rethrows when the stored data is invalid JSON.
    ///
    func test_getDeviceAuthKeyMetadata_invalidData() async {
        keychainServiceFacade.getValueReturnValue = "invalid-json"

        await assertAsyncThrows {
            _ = try await subject.getDeviceAuthKeyMetadata(userId: "1")
        }
    }

    /// `setDeviceAuthKey(record:metadata:userId:)` stores the record first, then metadata, via the facade.
    ///
    func test_setDeviceAuthKey() async throws {
        var setArgs: [(value: String, key: String)] = []
        keychainServiceFacade.setValueClosure = { value, item in
            setArgs.append((value: value, key: item.unformattedKey))
        }

        let record = DeviceAuthKeyRecord.fixture()
        let metadata = DeviceAuthKeyMetadata.fixture()
        try await subject.setDeviceAuthKey(record: record, metadata: metadata, userId: "1")

        XCTAssertEqual(setArgs.count, 2)
        XCTAssertEqual(setArgs[0].key, BitwardenKeychainItem.deviceAuthKey(userId: "1").unformattedKey)
        XCTAssertEqual(setArgs[1].key, BitwardenKeychainItem.deviceAuthKeyMetadata(userId: "1").unformattedKey)

        let decodedRecord = try JSONDecoder.defaultDecoder.decode(
            DeviceAuthKeyRecord.self,
            from: XCTUnwrap(setArgs[0].value.data(using: .utf8)),
        )
        XCTAssertEqual(decodedRecord, record)

        let decodedMetadata = try JSONDecoder.defaultDecoder.decode(
            DeviceAuthKeyMetadata.self,
            from: XCTUnwrap(setArgs[1].value.data(using: .utf8)),
        )
        XCTAssertEqual(decodedMetadata, metadata)
    }

    /// `setDeviceAuthKey(record:metadata:userId:)` rethrows errors from the facade.
    ///
    func test_setDeviceAuthKey_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainServiceFacade.setValueThrowableError = error

        await assertAsyncThrows(error: error) {
            try await subject.setDeviceAuthKey(
                record: DeviceAuthKeyRecord.fixture(),
                metadata: DeviceAuthKeyMetadata.fixture(),
                userId: "1",
            )
        }
    }
}
