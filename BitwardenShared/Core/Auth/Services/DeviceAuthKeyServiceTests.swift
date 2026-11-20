import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - DeviceAuthKeyServiceTests

final class DeviceAuthKeyServiceTests: BitwardenTestCase {
    // MARK: Properties

    var activeAccountStateProvider: MockActiveAccountStateProvider!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var deviceAuthKeychainRepository: MockDeviceAuthKeychainRepository!
    var environmentService: MockEnvironmentService!
    var stateService: MockStateService!
    var subject: DefaultDeviceAuthKeyService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        activeAccountStateProvider = MockActiveAccountStateProvider()
        clientService = MockClientService()
        configService = MockConfigService()
        deviceAuthKeychainRepository = MockDeviceAuthKeychainRepository()
        environmentService = MockEnvironmentService()
        stateService = MockStateService()

        subject = DefaultDeviceAuthKeyService(
            activeAccountStateProvider: activeAccountStateProvider,
            clientService: clientService,
            configService: configService,
            deviceAuthKeychainRepository: deviceAuthKeychainRepository,
            environmentService: environmentService,
            stateService: stateService,
            systemDevice: MockSystemDevice(),
        )
    }

    override func tearDown() {
        super.tearDown()

        activeAccountStateProvider = nil
        clientService = nil
        configService = nil
        deviceAuthKeychainRepository = nil
        environmentService = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests - deleteDeviceAuthKey

    /// `deleteDeviceAuthKey(userId:)` successfully deletes the device auth key from the keychain repository.
    ///
    func test_deleteDeviceAuthKey_success() async throws {
        deviceAuthKeychainRepository.getDeviceAuthKeyMetadataReturnValue = nil
        try await subject.deleteDeviceAuthKey(userId: "userId123")

        XCTAssertEqual(deviceAuthKeychainRepository.deleteDeviceAuthKeyCallsCount, 1)
        XCTAssertEqual(deviceAuthKeychainRepository.deleteDeviceAuthKeyReceivedUserId, "userId123")
    }

    /// `deleteDeviceAuthKey(userId:)` throws an error from the keychain repository.
    ///
    func test_deleteDeviceAuthKey_throwsError() async throws {
        let expectedError = BitwardenTestError.example
        deviceAuthKeychainRepository.getDeviceAuthKeyMetadataReturnValue = nil
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
        let metadata = DeviceAuthKeyKeychainMetadata.fixture()
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
