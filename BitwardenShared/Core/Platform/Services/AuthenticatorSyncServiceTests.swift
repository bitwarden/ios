import AuthenticatorBridgeKit
import AuthenticatorBridgeKitMocks
import BitwardenKitMocks
import BitwardenSdk
import Combine
import TestHelpers
import XCTest

@testable import BitwardenShared

final class AuthenticatorSyncServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    var authBridgeItemService: MockAuthenticatorBridgeItemService!
    var authenticatorClientService: MockClientService!
    var cipherDataStore: MockCipherDataStore!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var keychainRepository: MockKeychainRepository!
    var organizationService: MockOrganizationService!
    var sharedKeychainRepository: MockSharedKeychainRepository!
    var stateService: MockStateService!
    var subject: DefaultAuthenticatorSyncService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        authBridgeItemService = MockAuthenticatorBridgeItemService()
        authenticatorClientService = MockClientService()
        cipherDataStore = MockCipherDataStore()
        configService = MockConfigService()
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        keychainRepository = MockKeychainRepository()
        organizationService = MockOrganizationService()
        sharedKeychainRepository = MockSharedKeychainRepository()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultAuthenticatorSyncService(
            authBridgeItemService: authBridgeItemService,
            authenticatorClientService: authenticatorClientService,
            cipherDataStore: cipherDataStore,
            clientService: clientService,
            configService: configService,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository,
            organizationService: organizationService,
            sharedKeychainRepository: sharedKeychainRepository,
            stateService: stateService,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
        authBridgeItemService = nil
        authenticatorClientService = nil
        cipherDataStore = nil
        configService = nil
        clientService = nil
        errorReporter = nil
        keychainRepository = nil
        organizationService = nil
        sharedKeychainRepository = nil
        stateService = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// When the user has subscribed to sync and has an unlocked vault, the
    /// `createAuthenticatorKeyIfNeeded` method successfully creates the sync key
    /// if it is not already present
    ///
    @MainActor
    func test_createAuthenticatorKeyIfNeeded_createsKeyWhenNeeded() async throws {
        setupInitialState()
        await subject.start()
        try sharedKeychainRepository.deleteAuthenticatorKey()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        try await waitForAsync {
            self.sharedKeychainRepository.authenticatorKey != nil
        }
    }

    /// When the user has subscribed to sync and has an unlocked vault, the
    /// `createAuthenticatorKeyIfNeeded` method successfully retrieves the key in
    /// SharedKeyRepository and doesn't recreate it.
    ///
    @MainActor
    func test_createAuthenticatorKeyIfNeeded_keyAlreadyExists() async throws {
        setupInitialState()
        await subject.start()
        let key = sharedKeychainRepository.generateMockKeyData()
        try await sharedKeychainRepository.setAuthenticatorKey(key)

        stateService.syncToAuthenticatorSubject.send(("1", true))

        try await waitForAsync {
            self.sharedKeychainRepository.authenticatorKey != nil
        }
        XCTAssertEqual(sharedKeychainRepository.authenticatorKey, key)
    }

    /// When the user has subscribed to sync and has an unlocked vault, the
    /// `createAuthenticatorVaultKeyIfNeeded` method successfully stores a copy
    /// of the user's vault key in the keychain if it is not already present.
    ///
    @MainActor
    func test_createAuthenticatorVaultKeyIfNeeded_createsKeyWhenNeeded() async throws {
        setupInitialState()
        await subject.start()
        try await keychainRepository.deleteAuthenticatorVaultKey(userId: "1")
        stateService.syncToAuthenticatorSubject.send(("1", true))

        try await waitForAsync {
            self.keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] != nil
        }
        XCTAssertEqual(authenticatorClientService.mockCrypto.getUserEncryptionKeyCalled, false)
        XCTAssertEqual(clientService.mockCrypto.getUserEncryptionKeyCalled, true)
    }

    /// When the user has subscribed to sync and has an unlocked vault, the
    /// `createAuthenticatorVaultKeyIfNeeded` method successfully handles an
    /// error in retrieving the user's vault key.
    ///
    @MainActor
    func test_createAuthenticatorVaultKeyIfNeeded_cryptoError() async throws {
        setupInitialState()
        await subject.start()
        clientService.mockCrypto.getUserEncryptionKeyResult = .failure(BitwardenTestError.example)
        stateService.syncToAuthenticatorSubject.send(("1", true))

        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }
    }

    /// When the user has subscribed to sync and has an unlocked vault, the
    /// `createAuthenticatorVaultKeyIfNeeded` method safely returns when the key
    /// doesn't need to be created.
    ///
    @MainActor
    func test_createAuthenticatorVaultKeyIfNeeded_keyAlreadyExists() async throws {
        setupInitialState()
        await subject.start()
        keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] =
            "AUTHENTICATOR_VAULT_KEY"

        stateService.syncToAuthenticatorSubject.send(("1", true))

        waitFor(keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] != nil)
        XCTAssertEqual(keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"],
                       "AUTHENTICATOR_VAULT_KEY")
    }

    /// When the user has subscribed to sync and has an unlocked vault, the
    /// `createAuthenticatorVaultKeyIfNeeded` method successfully handles an
    /// error in storing the user's vault key in the keychain.
    ///
    @MainActor
    func test_createAuthenticatorVaultKeyIfNeeded_keychainError() async throws {
        setupInitialState()
        await subject.start()
        keychainRepository.setAuthenticatorVaultKeyResult = .failure(BitwardenTestError.example)
        stateService.syncToAuthenticatorSubject.send(("1", true))

        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }
    }

    /// When the user has subscribed to sync and has an unlocked vault, but is **not** the active user,
    /// `createAuthenticatorVaultKeyIfNeeded` method should return without attempting to
    /// store the user's key.
    ///
    @MainActor
    func test_createAuthenticatorVaultKeyIfNeeded_notActiveUser() async throws {
        setupInitialState()
        await subject.start()
        await stateService.addAccount(.fixtureAccountLogin())
        stateService.syncToAuthenticatorSubject.send(("1", true))

        XCTAssertNil(keychainRepository.mockStorage["authenticatorVaultKey_1"])
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
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
            .fixture(
                deletedDate: Date(timeIntervalSinceNow: -10000),
                id: "Deleted",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            self.authBridgeItemService.storedItems["1"]?.first != nil
        }

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
                    username: "masked@example.com",
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
        try await waitForAsync {
            self.authBridgeItemService.storedItems["1"]?.first != nil
        }

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
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            self.authBridgeItemService.storedItems["1"]?.first != nil
        }

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.accountDomain, "vault.bitwarden.com")
        XCTAssertEqual(item.accountEmail, "user@bitwarden.com")
        XCTAssertEqual(item.favorite, false)
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "masked@example.com")
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
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            self.authBridgeItemService.storedItems["1"]?.first != nil
        }

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.accountDomain, "vault.bitwarden.com")
        XCTAssertEqual(item.accountEmail, "user@bitwarden.com")
        XCTAssertEqual(item.favorite, false)
        XCTAssertEqual(item.id, "1234")
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "masked@example.com")
    }

    /// Verifies that the AuthSyncService handles an error when attempting to fetch the accounts to check
    /// if any are left with sync.
    ///
    @MainActor
    func test_deleteKeyIfSyncingIsOff_errorFetchingAccounts() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        try await waitForAsync {
            self.sharedKeychainRepository.authenticatorKey != nil
        }

        stateService.accounts = nil
        stateService.syncToAuthenticatorByUserId["1"] = false
        stateService.syncToAuthenticatorSubject.send(("1", false))

        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }
    }

    /// Verifies that the AuthSyncService handles a keychain error when attempting to remove the Authenticator key.
    ///
    @MainActor
    func test_deleteKeyIfSyncingIsOff_errorInKeychain() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        try await waitForAsync {
            self.sharedKeychainRepository.authenticatorKey != nil
        }

        sharedKeychainRepository.errorToThrow = BitwardenTestError.example
        stateService.syncToAuthenticatorByUserId["1"] = false
        stateService.syncToAuthenticatorSubject.send(("1", false))

        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }
    }

    /// Verifies that the AuthSyncService removes the Authenticator key when the last account to sync is turned off.
    ///
    @MainActor
    func test_deleteKeyIfSyncingIsOff_lastAccountSyncTurnedOff() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        try await waitForAsync {
            self.sharedKeychainRepository.authenticatorKey != nil
        }
        stateService.syncToAuthenticatorByUserId["1"] = false
        stateService.syncToAuthenticatorSubject.send(("1", false))

        try await waitForAsync {
            self.sharedKeychainRepository.authenticatorKey == nil
        }
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
        try await waitForAsync {
            self.sharedKeychainRepository.authenticatorKey != nil
        }

        stateService.syncToAuthenticatorByUserId["1"] = false
        stateService.syncToAuthenticatorSubject.send(("1", false))
        try await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertNotNil(sharedKeychainRepository.authenticatorKey)
    }

    /// Verifies that the AuthSyncService removes the Authenticator vault key when a user turns off sync
    /// for their account.
    ///
    @MainActor
    func test_determineSyncForUserId_deletesAuthenticatorVaultKey() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))

        try await waitForAsync {
            self.keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] != nil
        }
        stateService.syncToAuthenticatorByUserId["1"] = false
        stateService.syncToAuthenticatorSubject.send(("1", false))

        try await waitForAsync {
            self.keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] == nil
        }
    }

    /// Verifies that the AuthSyncService handles and reports errors when sync is turned off and the
    /// service attempts to delete this account's items from the Store.
    ///
    @MainActor
    func test_determineSyncForUserId_errorFromDeleteAllItems() async throws {
        setupInitialState()
        await subject.start()

        authBridgeItemService.errorToThrow = BitwardenTestError.example
        stateService.syncToAuthenticatorByUserId["1"] = false
        stateService.syncToAuthenticatorSubject.send(("1", false))
        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }
    }

    /// Verifies that the AuthSyncService handles and reports errors when and there is an error
    /// thrown while accessing the sync setting for the account.
    ///
    @MainActor
    func test_determineSyncForUserId_errorFromFetchingSyncSetting() async throws {
        setupInitialState()
        await subject.start()

        stateService.syncToAuthenticatorResult = .failure(BitwardenTestError.example)
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }
    }

    /// Verifies that the AuthSyncService handles and reports errors when sync is turned On and the
    /// keychain throws an error.
    ///
    @MainActor
    func test_determineSyncForUserId_errorFromKeychain() async throws {
        setupInitialState()
        await subject.start()
        keychainRepository.setAuthenticatorVaultKeyResult = .failure(BitwardenTestError.example)

        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }
    }

    /// Verifies that the AuthSyncService handles and reports errors when sync is turned On and the
    /// shared keychain throws an error.
    ///
    @MainActor
    func test_determineSyncForUserId_errorFromSharedKeychain() async throws {
        setupInitialState()
        await subject.start()
        sharedKeychainRepository.errorToThrow = BitwardenTestError.example

        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }
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
        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }
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
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])
        try await waitForAsync {
            self.authBridgeItemService.storedItems["1"]?.first != nil
        }

        // Unsubscribe from sync, wait for items to be deleted
        stateService.syncToAuthenticatorByUserId["1"] = false
        stateService.syncToAuthenticatorSubject.send(("1", false))
        try await waitForAsync {
            (self.authBridgeItemService.storedItems["1"]?.isEmpty) ?? false
        }

        // Sending additional updates should not appear in Store
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])

        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertTrue(authBridgeItemService.storedItems["1"]?.isEmpty ?? false)
    }

    /// The sync service should be properly handling multiple publishes which could happen on multiple threads.
    /// By generating a `send` on both the sync status and the vault unlock, the service will receive two
    /// simultaneous attempts to determine syncing.
    ///
    @MainActor
    func test_determineSyncForUserId_threadSafetyCheck() async throws {
        setupInitialState()
        await subject.start()

        for _ in 0 ..< 4 {
            async let result1: Void = stateService.syncToAuthenticatorSubject.send(("1", true))
            async let result2: Void = vaultTimeoutService.vaultLockStatusSubject.send(
                VaultLockStatus(isVaultLocked: false, userId: "1")
            )
            await _ = (result1, result2)
        }

        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])
        try await waitForAsync {
            self.authBridgeItemService.storedItems["1"]?.first != nil
        }
    }

    /// When user "1" has sync turned on and user "2" unlocks their vault, the service should not take
    /// any action because "1" has a locked vault and "2" doesn't have sync turned on.
    ///
    @MainActor
    func test_determineSyncForUserId_unlockDifferentVault() async throws {
        setupInitialState(vaultLocked: true)
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
                    username: "masked@example.com",
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
        // swiftlint:disable:previous function_body_length
        setupInitialState()
        cipherDataStore.cipherSubjectByUserId["2"] = CurrentValueSubject<[Cipher], Error>([])
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])

        try await waitForAsync { self.authBridgeItemService.storedItems["1"]?.first != nil }

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.accountDomain, "vault.bitwarden.com")
        XCTAssertEqual(item.accountEmail, "user@bitwarden.com")
        XCTAssertEqual(item.favorite, false)
        XCTAssertEqual(item.id, "1234")
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "masked@example.com")
        await stateService.addAccount(.fixture(
            profile: .fixture(email: "different@bitwarden.com", userId: "2"),
            settings: .fixture(environmentURLs: .fixture(webVault: URL(string: "https://vault.example.com")))
        ))
        stateService.accountEncryptionKeys["2"] = AccountEncryptionKeys(
            encryptedPrivateKey: "privateKey_2",
            encryptedUserKey: "userKey_2"
        )
        stateService.syncToAuthenticatorByUserId["2"] = true
        vaultTimeoutService.isClientLocked["2"] = false
        stateService.syncToAuthenticatorSubject.send(("2", true))
        cipherDataStore.cipherSubjectByUserId["2"]?.send([
            .fixture(
                id: "4321",
                login: .fixture(
                    username: "masked2@example.com",
                    totp: "totp2"
                )
            ),
        ])

        try await waitForAsync { self.authBridgeItemService.storedItems["2"]?.first != nil }

        let otherItem = try XCTUnwrap(authBridgeItemService.storedItems["2"]?.first)
        XCTAssertEqual(otherItem.accountDomain, "vault.example.com")
        XCTAssertEqual(otherItem.accountEmail, "different@bitwarden.com")
        XCTAssertEqual(otherItem.favorite, false)
        XCTAssertEqual(otherItem.id, "4321")
        XCTAssertEqual(otherItem.name, "Bitwarden")
        XCTAssertEqual(otherItem.totpKey, "totp2")
        XCTAssertEqual(otherItem.username, "masked2@example.com")
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
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])

        try await waitForAsync {
            self.authBridgeItemService.storedItems["1"]?.first != nil
        }

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.accountDomain, "vault.bitwarden.com")
        XCTAssertEqual(item.accountEmail, "user@bitwarden.com")
        XCTAssertEqual(item.favorite, false)
        XCTAssertEqual(item.id, "1234")
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "masked@example.com")
    }

    /// Verifies that the AuthSyncService uses the previously stored AuthenticatorVaultKey
    /// when the user's vault is locked.
    ///
    @MainActor
    func test_determineSyncForUserId_vaultLocked() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            self.keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] != nil
        }

        vaultTimeoutService.isClientLocked["1"] = true
        vaultTimeoutService.vaultLockStatusSubject.send(
            VaultLockStatus(isVaultLocked: true, userId: "1")
        )
        try await Task.sleep(nanoseconds: 10_000_000)

        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])

        try await waitForAsync {
            self.authBridgeItemService.storedItems["1"]?.first != nil
        }

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.accountDomain, "vault.bitwarden.com")
        XCTAssertEqual(item.accountEmail, "user@bitwarden.com")
        XCTAssertEqual(item.favorite, false)
        XCTAssertEqual(item.id, "1234")
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "masked@example.com")
    }

    /// Verifies that the AuthSyncService uses the previously stored AuthenticatorVaultKey
    /// when the user's vault is locked even when they are not the active user.
    ///
    @MainActor
    func test_determineSyncForUserId_vaultLockedAndNotActiveUser() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            self.keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] != nil
        }

        await stateService.addAccount(.fixtureAccountLogin())
        vaultTimeoutService.isClientLocked["1"] = true
        vaultTimeoutService.vaultLockStatusSubject.send(
            VaultLockStatus(isVaultLocked: true, userId: "1")
        )
        try await Task.sleep(nanoseconds: 10_000_000)

        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])

        try await waitForAsync {
            self.authBridgeItemService.storedItems["1"]?.first != nil
        }

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.id, "1234")
    }

    /// Verifies that the AuthSyncService uses the previously stored AuthenticatorVaultKey
    /// when the user's vault is locked at the initial startup of the service - i.e. if the  AuthenticatorVaultKey
    /// exists, there's no need to wait for vault unlock.
    ///
    @MainActor
    func test_determineSyncForUserId_vaultLockedAtStartup() async throws {
        setupInitialState(vaultLocked: true)
        let key = try await authenticatorClientService.crypto().getUserEncryptionKey()
        try await keychainRepository.setAuthenticatorVaultKey(key, userId: "1")
        await subject.start()

        stateService.syncToAuthenticatorSubject.send(("1", true))
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])

        try await waitForAsync {
            self.authBridgeItemService.storedItems["1"]?.first != nil
        }

        let item = try XCTUnwrap(authBridgeItemService.storedItems["1"]?.first)
        XCTAssertEqual(item.accountDomain, "vault.bitwarden.com")
        XCTAssertEqual(item.accountEmail, "user@bitwarden.com")
        XCTAssertEqual(item.favorite, false)
        XCTAssertEqual(item.id, "1234")
        XCTAssertEqual(item.name, "Bitwarden")
        XCTAssertEqual(item.totpKey, "totp")
        XCTAssertEqual(item.username, "masked@example.com")
    }

    /// When the `AuthenticatorBridgeItemService` throws an error , `getTemporaryTotpItem()`  returns `nil`.
    ///
    @MainActor
    func test_getTemporaryTotpItem_error() async throws {
        authBridgeItemService.errorToThrow = BitwardenTestError.example
        let result = await subject.getTemporaryTotpItem()
        XCTAssertNil(result)
        XCTAssertFalse(errorReporter.errors.isEmpty)
    }

    /// When there is no item, `getTemporaryTotpItem()` always returns `nil`.
    ///
    @MainActor
    func test_getTemporaryTotpItem_noItem() async throws {
        authBridgeItemService.tempItem = nil
        let result = await subject.getTemporaryTotpItem()
        XCTAssertNil(result)
    }

    /// `getTemporaryTotpItem()` returns the stored temporary item.
    ///
    @MainActor
    func test_getTemporaryTotpItem_success() async throws {
        let expected = AuthenticatorBridgeItemDataView(
            accountDomain: nil,
            accountEmail: nil,
            favorite: false,
            id: "id",
            name: "name",
            totpKey: "totpKey",
            username: nil
        )
        authBridgeItemService.tempItem = expected
        let result = await subject.getTemporaryTotpItem()
        XCTAssertEqual(expected, result)
    }

    /// If the `start()` method is called multiple times, it should only start once - i.e. only one set of listeners,
    /// no double sync, etc.
    ///
    @MainActor
    func test_start_multipleStartsIgnored() async throws {
        setupInitialState()
        async let first: Void = subject.start()
        async let second: Void = subject.start()
        _ = await (first, second)
        stateService.syncToAuthenticatorSubject.send(("1", true))
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])

        try await waitForAsync {
            self.authBridgeItemService.storedItems["1"]?.first != nil
        }
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

        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }
    }

    /// The AuthService may not get notified about Vault locking if the user has switched accounts. Verify
    /// that it unlocks the vault if the user has a previously stored Authenticator Vault Key, syncs ciphers, and
    /// then re-locks the vault.
    ///
    @MainActor
    func test_writeCiphers_vaultLocked() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            self.keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] != nil
        }

        vaultTimeoutService.isClientLocked["1"] = true
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])

        try await waitForAsync { self.authBridgeItemService.storedItems["1"]?.first != nil }
        let items = try XCTUnwrap(authBridgeItemService.storedItems["1"])
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "1234")
        XCTAssertNotNil(authenticatorClientService.mockCrypto.initializeUserCryptoRequest)
        XCTAssertNotNil(authenticatorClientService.mockCrypto.initializeOrgCryptoRequest)
        XCTAssertTrue(authenticatorClientService.userClientArray.isEmpty)
    }

    /// The AuthService may not get notified about Vault locking if the user has switched accounts. Verify
    /// that it unlocks the vault if the user has a previously stored Authenticator Vault Key, syncs ciphers, and
    /// then re-locks the vault for a user which has organization ciphers.
    ///
    @MainActor
    func test_writeCiphers_vaultLocked_withOrgCiphers() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            self.keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] != nil
        }

        vaultTimeoutService.isClientLocked["1"] = true
        organizationService.fetchAllOrganizationsUserIdResult = .success([.fixture(id: "org-1", key: "key-org-1")])
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                ),
                organizationId: "org-1"
            ),
        ])

        try await waitForAsync { self.authBridgeItemService.storedItems["1"]?.first != nil }
        let items = try XCTUnwrap(authBridgeItemService.storedItems["1"])
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "1234")
        XCTAssertNotNil(authenticatorClientService.mockCrypto.initializeUserCryptoRequest)
        XCTAssertNotNil(authenticatorClientService.mockCrypto.initializeOrgCryptoRequest)
        XCTAssertEqual(
            authenticatorClientService.mockCrypto.initializeOrgCryptoRequest?.organizationKeys, ["org-1": "key-org-1"]
        )
        XCTAssertTrue(authenticatorClientService.userClientArray.isEmpty)
    }

    /// Verify that `writeCiphers()` correctly reports errors from unlocking a locked vault with
    /// the AuthenticatorVaultKey.
    ///
    @MainActor
    func test_writeCiphers_vaultLockedUnlockError() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            self.keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] != nil
        }

        authenticatorClientService.mockCrypto.initializeUserCryptoResult = .failure(BitwardenTestError.example)
        vaultTimeoutService.isClientLocked["1"] = true
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])

        try await waitForAsync { !self.errorReporter.errors.isEmpty }
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "1"))
    }

    /// Verify that `writeCiphers()` correctly catches and logs errors that occur in `decryptTOTPs`. The user's vault is
    /// re-locked at the end of error handling.
    ///
    @MainActor
    func test_writeCiphers_vaultLockedDecryptTOTPsError() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            self.keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] != nil
        }

        authenticatorClientService.mockVault.clientCiphers.decryptResult = { _ in
            throw BitwardenTestError.example
        }
        vaultTimeoutService.isClientLocked["1"] = true
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])

        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "1"))
    }

    /// Verify that `writeCiphers()` correctly catches and logs errors that occur in `replaceAllItems`.
    /// The user's vault is re-locked at the end of error handling.
    ///
    @MainActor
    func test_writeCiphers_vaultLockedAuthBridgeError() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            self.keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] != nil
        }

        authBridgeItemService.errorToThrow = BitwardenTestError.example
        vaultTimeoutService.isClientLocked["1"] = true
        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])

        try await waitForAsync {
            !self.errorReporter.errors.isEmpty
        }
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "1"))
    }

    /// Verify that ciphers are decrypted and synced successfully when the vault is unlocked. Verify that an unlocked
    /// vault is not locked when it was unlocked to begin with.
    ///
    @MainActor
    func test_writeCiphers_vaultUnlocked() async throws {
        setupInitialState()
        await subject.start()
        stateService.syncToAuthenticatorSubject.send(("1", true))
        try await waitForAsync {
            self.keychainRepository.mockStorage["bwKeyChainStorage:mockAppId:authenticatorVaultKey_1"] != nil
        }

        cipherDataStore.cipherSubjectByUserId["1"]?.send([
            .fixture(
                id: "1234",
                login: .fixture(
                    username: "masked@example.com",
                    totp: "totp"
                )
            ),
        ])
        try await waitForAsync {
            self.authBridgeItemService.storedItems["1"]?.first != nil
        }
        XCTAssertFalse(vaultTimeoutService.isClientLocked["1"] ?? true)
        XCTAssertNotNil(authenticatorClientService.mockCrypto.initializeUserCryptoRequest)
        XCTAssertNotNil(authenticatorClientService.mockCrypto.initializeOrgCryptoRequest)
    }

    // MARK: - Private Methods

    /// Helper function that sets up the common test condition of sync being turned on.
    ///
    /// - Parameters:
    ///   - vaultLocked: The state of the vault - `true` means the vault is locked.
    ///     `false` means the vault is unlocked. Defaults to `false`
    ///
    @MainActor
    private func setupInitialState(vaultLocked: Bool = false) {
        cipherDataStore.cipherSubjectByUserId["1"] = CurrentValueSubject<[Cipher], Error>([])
        stateService.activeAccount = .fixture()
        stateService.accounts = [.fixture()]
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            encryptedPrivateKey: "privateKey",
            encryptedUserKey: "userKey"
        )
        stateService.syncToAuthenticatorByUserId["1"] = true
        vaultTimeoutService.isClientLocked["1"] = vaultLocked
    }
} // swiftlint:disable:this file_length
