import AuthenticatorBridgeKit
import BitwardenSdk
import Combine
import XCTest

@testable import BitwardenShared

final class AuthenticatorSyncServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    var authBridgeItemService: MockAuthenticatorBridgeItemService!
    var cipherDataStore: MockCipherDataStore!
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
        cipherDataStore = MockCipherDataStore()
        configService = MockConfigService()
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        notificationCenterService = MockNotificationCenterService()
        sharedKeychainRepository = MockSharedKeychainRepository()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultAuthenticatorSyncService(
            authBridgeItemService: authBridgeItemService,
            cipherDataStore: cipherDataStore,
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
        cipherDataStore = nil
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
    @MainActor
    func test_createAuthenticatorKeyIfNeeded_createsKeyWhenNeeded() async throws {
        stateService.syncToAuthenticatorByUserId["1"] = true
        vaultTimeoutService.isClientLocked["1"] = false
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        try sharedKeychainRepository.deleteAuthenticatorKey()
        stateService.activeAccount = .fixture()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        waitFor(sharedKeychainRepository.authenticatorKey != nil)
    }

    /// When the app enters the foreground and the user has subscribed to sync, the
    /// `createAuthenticatorKeyIfNeeded` method successfully retrieves the key in
    /// SharedKeyRepository and doesn't recreate it.
    ///
    @MainActor
    func test_createAuthenticatorKeyIfNeeded_keyAlreadyExists() async throws {
        stateService.syncToAuthenticatorByUserId["1"] = true
        vaultTimeoutService.isClientLocked["1"] = false
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        let key = sharedKeychainRepository.generateKeyData()
        try await sharedKeychainRepository.setAuthenticatorKey(key)

        stateService.activeAccount = .fixture()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        waitFor(sharedKeychainRepository.authenticatorKey != nil)
        XCTAssertEqual(sharedKeychainRepository.authenticatorKey, key)
    }

    /// When Ciphers are published. the service filters out ones that have a deletedDate in the past.
    ///
    @MainActor
    func test_decryptTOTPs_filtersOutDeleted() async throws {
        stateService.syncToAuthenticatorByUserId["1"] = true
        vaultTimeoutService.isClientLocked["1"] = false
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        stateService.activeAccount = .fixture()
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
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
        waitFor(authBridgeItemService.replaceAllCalled)

        let items = try XCTUnwrap(authBridgeItemService.storedItems["1"])
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "1234")
    }

    /// When Ciphers are published. the service ignores any Ciphers with logins that don't contain a TOTP key.
    ///
    @MainActor
    func test_decryptTOTPs_ignoresItemsWithoutTOTP() async throws {
        stateService.syncToAuthenticatorByUserId["1"] = true
        vaultTimeoutService.isClientLocked["1"] = false
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        stateService.activeAccount = .fixture()
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
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
        waitFor(authBridgeItemService.replaceAllCalled)

        let items = try XCTUnwrap(authBridgeItemService.storedItems["1"])
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "1234")
    }

    /// Verifies that the AuthSyncService responds to new Ciphers published and provides a generated UUID if the
    /// Cipher has no id itself.
    ///
    @MainActor
    func test_decryptTOTPs_providesIdIfNil() async throws {
        stateService.syncToAuthenticatorByUserId["1"] = true
        vaultTimeoutService.isClientLocked["1"] = false
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        stateService.activeAccount = .fixture()
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
        ])
        stateService.syncToAuthenticatorSubject.send(("1", true))
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
    @MainActor
    func test_decryptTOTPs_success() async throws {
        stateService.syncToAuthenticatorByUserId["1"] = true
        vaultTimeoutService.isClientLocked["1"] = false
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        stateService.activeAccount = .fixture()
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
        ])
        stateService.syncToAuthenticatorSubject.send(("1", true))
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
    @MainActor
    func test_handleSyncOn_error() async throws {
        stateService.syncToAuthenticatorByUserId["1"] = true
        vaultTimeoutService.isClientLocked["1"] = false
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        sharedKeychainRepository.errorToThrow = BitwardenTestError.example

        stateService.activeAccount = .fixture()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        waitFor(!errorReporter.errors.isEmpty)
    }

    /// When the sync is turned on, but the vault is locked, the service should subscribe and wait
    /// for the vault unlock to occur.
    ///
    @MainActor
    func test_handleSyncOn_vaultLocked() async throws {
        stateService.syncToAuthenticatorByUserId["1"] = true
        vaultTimeoutService.isClientLocked["1"] = true
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        stateService.activeAccount = .fixture()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        vaultTimeoutService.isClientLocked["1"] = false
        vaultTimeoutService.vaultLockStatusSubject.send(
            VaultLockStatus(isVaultLocked: false, userId: "1")
        )

        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
        ])

        waitFor(authBridgeItemService.replaceAllCalled)

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.favorite, false)
        XCTAssertEqual(item.id, "1234")
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "user@bitwarden.com")
    }

    /// When user "1" has sync turned on and user "2" unlocks their vault, the service should not take
    /// any action because "1" has a locked vault and "2" doesn't have sync turned on.
    ///
    @MainActor
    func test_handleSyncOn_unlockDifferentVault() async throws {
        stateService.activeAccount = .fixture()
        stateService.syncToAuthenticatorByUserId["1"] = true
        vaultTimeoutService.isClientLocked["1"] = true
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        vaultTimeoutService.isClientLocked["2"] = false
        vaultTimeoutService.vaultLockStatusSubject.send(
            VaultLockStatus(isVaultLocked: false, userId: "2")
        )

        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
        ])

        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertFalse(authBridgeItemService.replaceAllCalled)
    }

    /// The sync service should handle multiple vaults being sync'd at the same time.
    ///
    @MainActor
    func test_handleSyncOn_unlockMultipleVaults() async throws {
        stateService.syncToAuthenticatorByUserId["1"] = true
        await stateService.addAccount(.fixture())
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        cipherDataStore.cipherSubjectByUserId["2"] = CurrentValueSubject<[Cipher], Error>([])
        vaultTimeoutService.isClientLocked["1"] = false
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
        ])
        waitFor(authBridgeItemService.replaceAllCalled)

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.favorite, false)
        XCTAssertEqual(item.id, "1234")
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "user@bitwarden.com")

        authBridgeItemService.replaceAllCalled = false

        await stateService.addAccount(.fixture(profile: .fixture(email: "different@bitwarden.com",
                                                                 userId: "2")))
        stateService.syncToAuthenticatorByUserId["2"] = true
        vaultTimeoutService.isClientLocked["2"] = false
        stateService.syncToAuthenticatorSubject.send(("2", true))

        cipherDataStore.cipherSubjectByUserId["2"]?.send([
            .fixture(
                id: "4321",
                login: .fixture(
                    username: "different@bitwarden.com",
                    totp: "totp2"
                )
            ),
        ])
        waitFor(authBridgeItemService.replaceAllCalled)

        let items = try XCTUnwrap(authBridgeItemService.storedItems["2"])
        let otherItem = try XCTUnwrap(items.first)
        XCTAssertEqual(otherItem.favorite, false)
        XCTAssertEqual(otherItem.id, "4321")
        XCTAssertEqual(otherItem.name, "Bitwarden")
        XCTAssertEqual(otherItem.totpKey, "totp2")
        XCTAssertEqual(otherItem.username, "different@bitwarden.com")
    }

    /// Verifies that the AuthSyncService stops listening for Cipher updates when the user has sync turned off.
    ///
    @MainActor
    func test_handleSyncOff() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        stateService.activeAccount = .fixture()
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", false))
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
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
    @MainActor
    func test_start_featureFlagOff() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = false
        stateService.activeAccount = .fixture()
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        await subject.start()
        try sharedKeychainRepository.deleteAuthenticatorKey()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertNil(sharedKeychainRepository.authenticatorKey)
    }

    /// Verifies that the AuthSyncService handles and reports errors thrown by the Cipher service..
    ///
    @MainActor
    func test_subscribeToCipherUpdates_error() async throws {
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        stateService.activeAccount = .fixture()
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        stateService.syncToAuthenticatorByUserId["1"] = true
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        notificationCenterService.willEnterForegroundSubject.send()

        cipherDataStore.cipherSubjectByUserId["1"]?.send(completion: .failure(BitwardenTestError.example))

        waitFor(!errorReporter.errors.isEmpty)
    }
} // swiftlint:disable:this file_length
