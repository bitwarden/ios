import AuthenticatorBridgeKit
import Combine
import XCTest

@testable import BitwardenShared

final class AuthenticatorSyncServiceTests: BitwardenTestCase {
    var authBridgeItemService: MockAuthenticatorBridgeItemService!
    var cipherService: MockCipherService!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var notificationCenterService: MockNotificationCenterService!
    var sharedKeychainRepository: MockSharedKeychainRepository!
    var stateService: MockStateService!
    var subject: DefaultAuthenticatorSyncService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        authBridgeItemService = MockAuthenticatorBridgeItemService()
        cipherService = MockCipherService()
        configService = MockConfigService()
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        notificationCenterService = MockNotificationCenterService()
        sharedKeychainRepository = MockSharedKeychainRepository()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultAuthenticatorSyncService(
            authBridgeItemService: authBridgeItemService,
            cipherService: cipherService,
            clientService: clientService,
            configService: configService,
            errorReporter: errorReporter,
            notificationCenterService: notificationCenterService,
            sharedKeychainRepository: sharedKeychainRepository,
            stateService: stateService,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        authBridgeItemService = nil
        cipherService = nil
        configService = nil
        clientService = nil
        errorReporter = nil
        notificationCenterService = nil
        sharedKeychainRepository = nil
        stateService = nil
        subject = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// When the app enters the foreground and the user has subscribed to sync, the
    /// `createAuthenticatorKeyIfNeeded` method successfully creates the sync key
    /// if it is not already present
    ///
    func test_createAuthenticatorKeyIfNeeded_createsKeyWhenNeeded() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        try sharedKeychainRepository.deleteAuthenticatorKey()
        stateService.activeAccount = .fixture()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        notificationCenterService.willEnterForegroundSubject.send()

        waitFor(sharedKeychainRepository.authenticatorKey != nil)
    }

    /// When the app enters the foreground and the user has subscribed to sync, the
    /// `createAuthenticatorKeyIfNeeded` method successfully retrieves the key in
    /// SharedKeyRepository and doesn't recreate it.
    ///
    func test_createAuthenticatorKeyIfNeeded_keyAlreadyExists() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        let key = sharedKeychainRepository.generateKeyData()
        try await sharedKeychainRepository.setAuthenticatorKey(key)

        stateService.activeAccount = .fixture()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        notificationCenterService.willEnterForegroundSubject.send()

        waitFor(sharedKeychainRepository.authenticatorKey != nil)
        XCTAssertEqual(sharedKeychainRepository.authenticatorKey, key)
    }

    /// When Ciphers are published. the service filters out ones that have a deletedDate in the past.
    ///
    func test_decryptTOTPs_filtersOutDeleted() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        stateService.activeAccount = .fixture()
        cipherService.ciphersSubject.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
            .fixture(
                deletedDate: Date(timeIntervalSinceNow: -10000),
                id: "Deleted",
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
        ])
        stateService.syncToAuthenticatorSubject.send(("1", true))
        notificationCenterService.willEnterForegroundSubject.send()

        waitFor(authBridgeItemService.replaceAllCalled)

        let items = try XCTUnwrap(authBridgeItemService.storedItems["1"])
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "1234")
    }

    /// When Ciphers are published. the service ignores any Ciphers with logins that don't contain a TOTP key.
    ///
    func test_decryptTOTPs_ignoresItemsWithoutTOTP() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        stateService.activeAccount = .fixture()
        cipherService.ciphersSubject.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
            .fixture(
                id: "No TOTP",
                login: .fixture(
                    username: "user@bitwarden.com"
                )
            ),
        ])
        stateService.syncToAuthenticatorSubject.send(("1", true))
        notificationCenterService.willEnterForegroundSubject.send()

        waitFor(authBridgeItemService.replaceAllCalled)

        let items = try XCTUnwrap(authBridgeItemService.storedItems["1"])
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "1234")
    }

    /// Verifies that the AuthSyncService responds to new Ciphers published and provides a generated UUID if the
    /// Cipher has no id itself.
    ///
    func test_decryptTOTPs_providesIdIfNil() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        stateService.activeAccount = .fixture()
        cipherService.ciphersSubject.send([
            .fixture(
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
        ])
        stateService.syncToAuthenticatorSubject.send(("1", true))
        notificationCenterService.willEnterForegroundSubject.send()

        waitFor(authBridgeItemService.replaceAllCalled)

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.favorite, false)
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "user@bitwarden.com")
    }

    /// Verifies that the AuthSyncService responds to new Ciphers published by converting them into ItemViews and
    /// passes them to the ItemService for storage.
    ///
    func test_decryptTOTPs_success() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        stateService.activeAccount = .fixture()
        cipherService.ciphersSubject.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
        ])
        stateService.syncToAuthenticatorSubject.send(("1", true))
        notificationCenterService.willEnterForegroundSubject.send()

        waitFor(authBridgeItemService.replaceAllCalled)

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.favorite, false)
        XCTAssertEqual(item.id, "1234")
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "user@bitwarden.com")
    }

    /// Verifies that the AuthSyncService handles and reports errors when sync is turned On..
    ///
    func test_handleSyncOn_error() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        sharedKeychainRepository.errorToThrow = BitwardenTestError.example

        stateService.activeAccount = .fixture()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        notificationCenterService.willEnterForegroundSubject.send()

        waitFor(!errorReporter.errors.isEmpty)
    }

    /// Verifies that the AuthSyncService stops listening for Cipher updates when the user has sync turned off.
    ///
    func test_handleSyncOff() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        stateService.activeAccount = .fixture()
        stateService.syncToAuthenticatorSubject.send(("1", false))
        notificationCenterService.willEnterForegroundSubject.send()
        cipherService.ciphersSubject.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
        ])

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(authBridgeItemService.replaceAllCalled)
    }

    /// Starting the service when the feature flag is off should do nothing - no subscriptions or responses.
    ///
    func test_start_featureFlagOff() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = false
        await subject.start()
        try sharedKeychainRepository.deleteAuthenticatorKey()
        stateService.activeAccount = .fixture()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        notificationCenterService.willEnterForegroundSubject.send()

        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertNil(sharedKeychainRepository.authenticatorKey)
    }

    /// Verifies that the AuthSyncService handles and reports errors thrown by the Cipher service..
    ///
    func test_subscribeToCipherUpdates_error() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        stateService.activeAccount = .fixture()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        notificationCenterService.willEnterForegroundSubject.send()
        cipherService.ciphersSubject.send(completion: .failure(BitwardenTestError.example))

        waitFor(!errorReporter.errors.isEmpty)
    }
}
