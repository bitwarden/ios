import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AuthServiceTests

@MainActor
class TrustDeviceServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appIDService: AppIDService!
    var appIDSettingsStore: MockAppIDSettingsStore!
    var authAPIService: AuthAPIService!
    var clientService: MockClientService!
    var keychainRepository: MockKeychainRepository!
    var stateService: MockStateService!
    var subject: DefaultTrustDeviceService!
    var client: MockHTTPClient!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        appIDSettingsStore = MockAppIDSettingsStore()
        appIDService = AppIDService(appIDSettingsStore: appIDSettingsStore)
        authAPIService = APIService(client: client)
        clientService = MockClientService()
        keychainRepository = MockKeychainRepository()
        stateService = MockStateService()

        subject = DefaultTrustDeviceService(
            appIDService: appIDService,
            authAPIService: authAPIService,
            clientService: clientService,
            keychainRepository: keychainRepository,
            stateService: stateService,
        )
        stateService.activeAccount = .fixture()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        appIDService = nil
        appIDSettingsStore = nil
        authAPIService = nil
        client = nil
        clientService = nil
        keychainRepository = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `getDeviceKey()` get the deviceKey of the trusted device.
    func test_getDeviceKey() async throws {
        // Set up the mock data.
        keychainRepository.getDeviceKeyReturnValue = "DEVICE_KEY"

        // Test.
        let deviceKey = try await subject.getDeviceKey()

        // Confirm the results.
        XCTAssertEqual(deviceKey, "DEVICE_KEY")
    }

    /// `trustDevice()` set the current device as trusted storing the keys and saving them server side.
    func test_trustDevice() async throws {
        // Set up the mock data.
        let trustDeviceResponse = TrustDeviceResponse(
            deviceKey: "DEVICE_KEY",
            protectedUserKey: "USER_KEY",
            protectedDevicePrivateKey: "DEVICE_PRIVATE_KEY",
            protectedDevicePublicKey: "DEVICE_PUBLIC_KEY",
        )
        client.results = [.httpSuccess(testData: .emptyResponse)]
        clientService.mockAuth.trustDeviceResult = .success(trustDeviceResponse)
        appIDSettingsStore.appID = "App ID"

        // Test.
        let result = try await subject.trustDevice()

        // Confirm the results.
        XCTAssertEqual(appIDSettingsStore.appID, "App ID")
        XCTAssertEqual(keychainRepository.setDeviceKeyReceivedArguments?.value, "DEVICE_KEY")
        XCTAssertEqual(trustDeviceResponse, result)
    }

    /// `trustDeviceIfNeeded()` set the current device as trusted storing the keys and saving them server side.
    ///  Executes if `shouldTrustDevice` is true
    func test_trustDeviceIfNeeded() async throws {
        // Set up the mock data.
        client.results = [.httpSuccess(testData: .emptyResponse)]
        let userId = try await stateService.getActiveAccountId()
        let trustDeviceResponse = TrustDeviceResponse(
            deviceKey: "DEVICE_KEY",
            protectedUserKey: "USER_KEY",
            protectedDevicePrivateKey: "DEVICE_PRIVATE_KEY",
            protectedDevicePublicKey: "DEVICE_PUBLIC_KEY",
        )
        clientService.mockAuth.trustDeviceResult = .success(trustDeviceResponse)
        stateService.shouldTrustDevice[userId] = true
        appIDSettingsStore.appID = "App ID"

        // Test.
        let result = try await subject.trustDeviceIfNeeded()

        // Confirm the results.
        XCTAssertEqual(appIDSettingsStore.appID, "App ID")
        XCTAssertEqual(keychainRepository.setDeviceKeyReceivedArguments?.value, "DEVICE_KEY")
        XCTAssertEqual(trustDeviceResponse, result)
    }

    /// `trustDeviceWithExistingKeys()` set the current device as trusted storing the keys and saving them server side.
    ///  Uses input as the keys to be store instead of being computed by authClient
    func test_trustDeviceWithExistingKeys() async throws {
        // Set up the mock data.
        client.results = [.httpSuccess(testData: .emptyResponse)]
        let userId = try await stateService.getActiveAccountId()
        let trustDeviceResponse = TrustDeviceResponse(
            deviceKey: "DEVICE_KEY",
            protectedUserKey: "USER_KEY",
            protectedDevicePrivateKey: "DEVICE_PRIVATE_KEY",
            protectedDevicePublicKey: "DEVICE_PUBLIC_KEY",
        )
        appIDSettingsStore.appID = "App ID"

        // Test.
        try await subject.trustDeviceWithExistingKeys(keys: trustDeviceResponse)

        // Confirm the results.
        XCTAssertEqual(appIDSettingsStore.appID, "App ID")
        XCTAssertEqual(keychainRepository.setDeviceKeyReceivedArguments?.value, "DEVICE_KEY")
    }

    /// `removeTrustedDevice()` set current device locally as not trusted.
    func test_removeTrustedDevice() async throws {
        // Set up the mock data.
        keychainRepository.getDeviceKeyReturnValue = "DEVICE_KEY"

        // Test.
        try await subject.removeTrustedDevice()

        // Confirm the results.
        XCTAssertTrue(keychainRepository.deleteDeviceKeyCalled)
    }

    /// `getShouldTrustDevice(:true)` get if device should be trusted.
    func test_getShouldTrustDevice_true() async throws {
        // Set up the mock data.
        let userId = try await stateService.getActiveAccountId()
        stateService.shouldTrustDevice[userId] = true

        // Test.
        let result = try await subject.getShouldTrustDevice()

        // Confirm the results.
        XCTAssertTrue(result)
    }

    /// `getShouldTrustDevice(:false)` get if device should be trusted.
    func test_getShouldTrustDevice_false() async throws {
        // Set up the mock data.
        let userId = try await stateService.getActiveAccountId()
        stateService.shouldTrustDevice[userId] = false

        // Test.
        let result = try await subject.getShouldTrustDevice()

        // Confirm the results.
        XCTAssertFalse(result)
    }

    /// `setShouldTrustDevice(:true)` set if device should be trusted.
    func test_setShouldTrustDevice_true() async throws {
        // Set up the mock data.
        let userId = try await stateService.getActiveAccountId()

        // Test.
        try await subject.setShouldTrustDevice(true)

        // Confirm the results.
        XCTAssertEqual(stateService.shouldTrustDevice[userId], true)
    }

    /// `setShouldTrustDevice(:false)` set if device should be trusted.
    func test_setShouldTrustDevice_false() async throws {
        // Set up the mock data.
        let userId = try await stateService.getActiveAccountId()

        // Test.
        try await subject.setShouldTrustDevice(false)

        // Confirm the results.
        XCTAssertEqual(stateService.shouldTrustDevice[userId], false)
    }

    /// `isDeviceTrusted(:true)` check if device is trusted.
    func test_isDeviceTrusted_true() async throws {
        // Set up the mock data.
        keychainRepository.getDeviceKeyReturnValue = "DEVICE_KEY"

        // Test.
        let result = try await subject.isDeviceTrusted()

        // Confirm the results.
        XCTAssertEqual(result, true)
    }

    /// `isDeviceTrusted(:false)` check if device is trusted.
    func test_isDeviceTrusted_false() async throws {
        // Test.
        let result = try await subject.isDeviceTrusted()

        // Confirm the results.
        XCTAssertEqual(result, false)
    }
}
