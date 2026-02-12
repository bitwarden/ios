import BitwardenKit
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - DeviceAuthKeyServiceTests

final class DeviceAuthKeyServiceTests: BitwardenTestCase {
    // MARK: Properties

    var deviceAuthKeychainRepository: MockDeviceAuthKeychainRepository!
    var subject: DefaultDeviceAuthKeyService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        deviceAuthKeychainRepository = MockDeviceAuthKeychainRepository()
        subject = DefaultDeviceAuthKeyService(
            deviceAuthKeychainRepository: deviceAuthKeychainRepository,
        )
    }

    override func tearDown() {
        super.tearDown()

        deviceAuthKeychainRepository = nil
        subject = nil
    }

    // MARK: Tests - assertDeviceAuthKey

    /// `assertDeviceAuthKey(for:recordIdentifier:userId:)` throws notImplemented error.
    ///
    func test_assertDeviceAuthKey_throwsNotImplemented() async throws {
        let allowedCredentials = [
            Data(repeating: 2, count: 32),
            Data(repeating: 5, count: 32),
        ]
        let passkeyParameters = MockPasskeyCredentialRequestParameters(allowedCredentials: allowedCredentials)
        let request = GetAssertionRequest(fido2RequestParameters: passkeyParameters)

        await assertAsyncThrows(error: DeviceAuthKeyError.notImplemented) {
            _ = try await subject.assertDeviceAuthKey(
                for: request,
                recordIdentifier: "record123",
                userId: "userId123",
            )
        }
    }

    // MARK: Tests - createDeviceAuthKey

    /// `createDeviceAuthKey(masterPasswordHash:overwrite:userId:)` throws notImplemented error.
    ///
    func test_createDeviceAuthKey_throwsNotImplemented() async throws {
        await assertAsyncThrows(error: DeviceAuthKeyError.notImplemented) {
            _ = try await subject.createDeviceAuthKey(
                masterPasswordHash: "hashedPassword",
                overwrite: false,
                userId: "userId123",
            )
        }
    }

    // MARK: Tests - deleteDeviceAuthKey

    /// `deleteDeviceAuthKey(userId:)` successfully deletes the device auth key from the keychain repository.
    ///
    func test_deleteDeviceAuthKey_success() async throws {
        try await subject.deleteDeviceAuthKey(userId: "userId123")

        XCTAssertEqual(deviceAuthKeychainRepository.deleteDeviceAuthKeyCallsCount, 1)
        XCTAssertEqual(deviceAuthKeychainRepository.deleteDeviceAuthKeyReceivedUserId, "userId123")
    }

    /// `deleteDeviceAuthKey(userId:)` throws an error from the keychain repository.
    ///
    func test_deleteDeviceAuthKey_throwsError() async throws {
        let expectedError = BitwardenTestError.example
        deviceAuthKeychainRepository.deleteDeviceAuthKeyThrowableError = expectedError

        await assertAsyncThrows(error: expectedError) {
            try await subject.deleteDeviceAuthKey(userId: "userId123")
        }

        XCTAssertEqual(deviceAuthKeychainRepository.deleteDeviceAuthKeyCallsCount, 1)
        XCTAssertEqual(deviceAuthKeychainRepository.deleteDeviceAuthKeyReceivedUserId, "userId123")
    }

    // MARK: Tests - getDeviceAuthKeyMetadata

    /// `getDeviceAuthKeyMetadata(userId:)` returns metadata from the keychain repository.
    ///
    func test_getDeviceAuthKeyMetadata_success() async throws {
        let metadata = DeviceAuthKeyMetadata.fixture()
        deviceAuthKeychainRepository.getDeviceAuthKeyMetadataReturnValue = metadata

        let result = try await subject.getDeviceAuthKeyMetadata(userId: "userId123")

        XCTAssertEqual(result, metadata)
        XCTAssertEqual(deviceAuthKeychainRepository.getDeviceAuthKeyMetadataCallsCount, 1)
        XCTAssertEqual(deviceAuthKeychainRepository.getDeviceAuthKeyMetadataReceivedUserId, "userId123")
    }

    /// `getDeviceAuthKeyMetadata(userId:)` returns nil when no metadata exists.
    ///
    func test_getDeviceAuthKeyMetadata_returnsNil() async throws {
        deviceAuthKeychainRepository.getDeviceAuthKeyMetadataReturnValue = nil

        let result = try await subject.getDeviceAuthKeyMetadata(userId: "userId123")

        XCTAssertNil(result)
        XCTAssertEqual(deviceAuthKeychainRepository.getDeviceAuthKeyMetadataCallsCount, 1)
        XCTAssertEqual(deviceAuthKeychainRepository.getDeviceAuthKeyMetadataReceivedUserId, "userId123")
    }

    /// `getDeviceAuthKeyMetadata(userId:)` throws an error from the keychain repository.
    ///
    func test_getDeviceAuthKeyMetadata_throwsError() async throws {
        let expectedError = BitwardenTestError.example
        deviceAuthKeychainRepository.getDeviceAuthKeyMetadataThrowableError = expectedError

        await assertAsyncThrows(error: expectedError) {
            _ = try await subject.getDeviceAuthKeyMetadata(userId: "userId123")
        }

        XCTAssertEqual(deviceAuthKeychainRepository.getDeviceAuthKeyMetadataCallsCount, 1)
        XCTAssertEqual(deviceAuthKeychainRepository.getDeviceAuthKeyMetadataReceivedUserId, "userId123")
    }
}
