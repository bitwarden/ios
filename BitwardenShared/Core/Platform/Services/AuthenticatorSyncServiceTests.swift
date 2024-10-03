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
        setupInitialState()
        await subject.start()
        try sharedKeychainRepository.deleteAuthenticatorKey()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        waitFor(sharedKeychainRepository.authenticatorKey != nil)
    }

    /// When the app enters the foreground and the user has subscribed to sync, the
    /// `createAuthenticatorKeyIfNeeded` method successfully retrieves the key in
    /// SharedKeyRepository and doesn't recreate it.
    ///
    @MainActor
    func test_createAuthenticatorKeyIfNeeded_keyAlreadyExists() async throws {
        setupInitialState()
        await subject.start()
        let key = sharedKeychainRepository.generateKeyData()
        try await sharedKeychainRepository.setAuthenticatorKey(key)

        stateService.syncToAuthenticatorSubject.send(("1", true))

        waitFor(sharedKeychainRepository.authenticatorKey != nil)
        XCTAssertEqual(sharedKeychainRepository.authenticatorKey, key)
    }

    /// When Ciphers are published. the service filters out ones that have a deletedDate in the past.
    ///
    @MainActor
    func test_decryptTOTPs_filtersOutDeleted() async throws {
        setupInitialState()
        await subject.start()
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
        waitFor(authBridgeItemService.storedItems["1"]?.first != nil)

        let items = try XCTUnwrap(authBridgeItemService.storedItems["1"])
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "1234")
    }

    /// When Ciphers are published. the service ignores any Ciphers with logins that don't contain a TOTP key.
    ///
    @MainActor
    func test_decryptTOTPs_ignoresItemsWithoutTOTP() async throws {
        setupInitialState()
        await subject.start()
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
        waitFor(authBridgeItemService.storedItems["1"]?.first != nil)

        let items = try XCTUnwrap(authBridgeItemService.storedItems["1"])
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "1234")
    }

    /// Verifies that the AuthSyncService responds to new Ciphers published and provides a generated UUID if the
    /// Cipher has no id itself.
    ///
    @MainActor
    func test_decryptTOTPs_providesIdIfNil() async throws {
        setupInitialState()
        await subject.start()
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
        ])
        stateService.syncToAuthenticatorSubject.send(("1", true))
        waitFor(authBridgeItemService.storedItems["1"]?.first != nil)

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
        setupInitialState()
        await subject.start()
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
        waitFor(authBridgeItemService.storedItems["1"]?.first != nil)

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.favorite, false)
        XCTAssertEqual(item.id, "1234")
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "user@bitwarden.com")
    }

    /// Verifies that the AuthSyncService removes the Authenticator key when the last account to sync is turned off.
    ///
    @MainActor
    func test_deleteKeyIfSyncingIsOff_lastAccountSyncTurnedOff() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        waitFor(sharedKeychainRepository.authenticatorKey != nil)
        stateService.syncToAuthenticatorByUserId["1"] = false
        stateService.syncToAuthenticatorSubject.send(("1", false))

        waitFor(sharedKeychainRepository.authenticatorKey == nil)
    }

    /// Verifies that the AuthSyncService does not removes the Authenticator key there are still
    /// accounts with sync is turned on.
    ///
    @MainActor
    func test_deleteKeyIfSyncingIsOff_notLastAccount() async throws {
        setupInitialState()
        stateService.accounts?.append(.fixture(profile: .fixture(userId: "2")))
        stateService.syncToAuthenticatorByUserId["2"] = true
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        waitFor(sharedKeychainRepository.authenticatorKey != nil)

        stateService.syncToAuthenticatorByUserId["1"] = false
        stateService.syncToAuthenticatorSubject.send(("1", false))
        try await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertNotNil(sharedKeychainRepository.authenticatorKey)
    }

    /// Verifies that the AuthSyncService handles and reports errors when sync is turned On..
    ///
    @MainActor
    func test_determineSyncForUserId_error() async throws {
        setupInitialState()
        await subject.start()
        sharedKeychainRepository.errorToThrow = BitwardenTestError.example

        stateService.syncToAuthenticatorSubject.send(("1", true))
        waitFor(!errorReporter.errors.isEmpty)
    }

    /// Verifies that the AuthSyncService handles and reports errors when vault is unlocked
    ///
    @MainActor
    func test_determineSyncForUserId_errorHandledByVaultSubscriber() async throws {
        setupInitialState()
        sharedKeychainRepository.errorToThrow = BitwardenTestError.example
        await subject.start()

        vaultTimeoutService.vaultLockStatusSubject.send(
            VaultLockStatus(isVaultLocked: false, userId: "1")
        )
        waitFor(!errorReporter.errors.isEmpty)
    }

    /// Verifies that the AuthSyncService stops listening for Cipher updates and removes all data in the shared store
    /// for a user when the user has sync turned off.
    ///
    @MainActor
    func test_determineSyncForUserId_syncTurnedOff() async throws {
        setupInitialState()
        await subject.start()

        // Send initial updates, record in Store
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
        waitFor(authBridgeItemService.storedItems["1"]?.first != nil)

        // Unsubscribe from sync, wait for items to be deleted
        stateService.syncToAuthenticatorByUserId["1"] = false
        stateService.syncToAuthenticatorSubject.send(("1", false))
        waitFor((authBridgeItemService.storedItems["1"]?.isEmpty) ?? false)

        // Sending additional updates should not appear in Store
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
        ])

        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertTrue(authBridgeItemService.storedItems["1"]?.isEmpty ?? false)
    }

    /// When user "1" has sync turned on and user "2" unlocks their vault, the service should not take
    /// any action because "1" has a locked vault and "2" doesn't have sync turned on.
    ///
    @MainActor
    func test_determineSyncForUserId_unlockDifferentVault() async throws {
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
    func test_determineSyncForUserId_unlockMultipleVaults() async throws {
        setupInitialState()
        cipherDataStore.cipherSubjectByUserId["2"] = CurrentValueSubject<[Cipher], Error>([])
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
        waitFor(authBridgeItemService.storedItems["1"]?.first != nil)

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.favorite, false)
        XCTAssertEqual(item.id, "1234")
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "user@bitwarden.com")

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
        waitFor(authBridgeItemService.storedItems["2"]?.first != nil)

        let otherItem = try XCTUnwrap(authBridgeItemService.storedItems["2"]?.first)
        XCTAssertEqual(otherItem.favorite, false)
        XCTAssertEqual(otherItem.id, "4321")
        XCTAssertEqual(otherItem.name, "Bitwarden")
        XCTAssertEqual(otherItem.totpKey, "totp2")
        XCTAssertEqual(otherItem.username, "different@bitwarden.com")
    }

    /// When the sync is turned on, but the vault is locked, the service should subscribe and wait
    /// for the vault unlock to occur.
    ///
    @MainActor
    func test_determineSyncForUserId_vaultUnlocked() async throws {
        setupInitialState(vaultLocked: true)
        await subject.start()
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

        waitFor(authBridgeItemService.storedItems["1"]?.first != nil)

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.favorite, false)
        XCTAssertEqual(item.id, "1234")
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "user@bitwarden.com")
    }

    /// Verifies that the AuthSyncService stops listening for Cipher updates when the user's vault is locked.
    ///
    @MainActor
    func test_determineSyncForUserId_vaultLocked() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await Task.sleep(nanoseconds: 10_000_000)

        vaultTimeoutService.isClientLocked["1"] = true
        vaultTimeoutService.vaultLockStatusSubject.send(
            VaultLockStatus(isVaultLocked: true, userId: "1")
        )
        try await Task.sleep(nanoseconds: 10_000_000)

        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "user@bitwarden.com",
                    totp: "totp"
                )
            ),
        ])

        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertNil(authBridgeItemService.storedItems["1"]?.first)
    }

    /// Starting the service when the feature flag is off should do nothing - no subscriptions or responses.
    ///
    @MainActor
    func test_start_featureFlagOff() async throws {
        setupInitialState()
        configService.featureFlagsBool[.enableAuthenticatorSync] = false
        await subject.start()
        try sharedKeychainRepository.deleteAuthenticatorKey()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertNil(sharedKeychainRepository.authenticatorKey)
    }

    /// If the `start()` method is called multiple times, it should only start once - i.e. only one set of listeners,
    /// no double sync, etc.
    ///
    @MainActor
    func test_start_multipleStartsIgnored() async throws {
        setupInitialState()
        await subject.start()
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

        waitFor(authBridgeItemService.storedItems["1"]?.first != nil)
        let items = try XCTUnwrap(authBridgeItemService.storedItems["1"])
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "1234")
    }

    /// Verifies that the AuthSyncService handles and reports errors thrown by the Cipher service.
    ///
    @MainActor
    func test_subscribeToCipherUpdates_error() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        cipherDataStore.cipherSubjectByUserId["1"]?.send(completion: .failure(BitwardenTestError.example))

        waitFor(!errorReporter.errors.isEmpty)
    }

    // MARK: - Private Methods

    /// Helper function that sets up testing parameters based on the flags passed in
    ///
    /// Note: The defaults passed in set everything up for sync to work immediately - sync on and vault unlocked.
    /// All that is necessary is to publish the sync setting or the vault status as-is to kick off sync. Override
    /// to turn sync off.
    ///
    /// - Parameters:
    ///   - syncOn: The state of the syncToAuthenticator feature flag. Defaults to `true`. `true` means sync is enabled.
    ///   - vaultLocked: The state of the vault - `true` means the vault is locked.
    ///     `false` means the vault is unlocked. Defaults to `false`
    ///
    @MainActor
    private func setupInitialState(syncOn: Bool = true, vaultLocked: Bool = false) {
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        stateService.activeAccount = .fixture()
        stateService.accounts = [.fixture()]
        stateService.syncToAuthenticatorByUserId["1"] = syncOn
        vaultTimeoutService.isClientLocked["1"] = vaultLocked
    }
} // swiftlint:disable:this file_length
