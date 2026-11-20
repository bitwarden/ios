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
    var deviceAuthKeychainRepository: MockDeviceAuthKeychainRepository!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: DefaultDeviceAuthKeyService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        activeAccountStateProvider = MockActiveAccountStateProvider()
        clientService = MockClientService()
        deviceAuthKeychainRepository = MockDeviceAuthKeychainRepository()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        subject = DefaultDeviceAuthKeyService(
            activeAccountStateProvider: activeAccountStateProvider,
            clientService: clientService,
            deviceAuthKeychainRepository: deviceAuthKeychainRepository,
            environmentService: environmentService,
            errorReporter: errorReporter,
            stateService: stateService,
            systemDevice: MockSystemDevice(),
        )
    }

    override func tearDown() {
        super.tearDown()

        activeAccountStateProvider = nil
        clientService = nil
        deviceAuthKeychainRepository = nil
        environmentService = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests - DeviceAuthKeyCrypto

    /// `DeviceAuthKeyCrypto.prfKey(hmacSecret:)` returns a base64 encoded 64-byte key.
    ///
    func test_prfKey_length() throws {
        let key = try DeviceAuthKeyCrypto.prfKey(hmacSecret: Data(repeating: 1, count: 32))
        XCTAssertEqual(Data(base64Encoded: key)?.count, 64)
    }

    /// `DeviceAuthKeyCrypto.webAuthnOrigin(for:)` keeps a port that isn't the default port.
    ///
    func test_webAuthnOrigin() throws {
        XCTAssertEqual(
            try DeviceAuthKeyCrypto.webAuthnOrigin(for: XCTUnwrap(URL(string: "https://localhost:8080/"))),
            "https://localhost:8080",
        )
        XCTAssertEqual(
            try DeviceAuthKeyCrypto.webAuthnOrigin(for: XCTUnwrap(URL(string: "https://vault.bitwarden.com:443"))),
            "https://vault.bitwarden.com",
        )
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
