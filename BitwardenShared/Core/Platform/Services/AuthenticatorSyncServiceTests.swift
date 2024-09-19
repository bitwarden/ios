import AuthenticatorBridgeKit
import XCTest

@testable import BitwardenShared

final class AuthenticatorSyncServiceTests: BitwardenTestCase {
    var application: MockApplication!
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

        application = MockApplication()
        authBridgeItemService = MockAuthenticatorBridgeItemService()
        cipherService = MockCipherService()
        configService = MockConfigService()
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        notificationCenterService = MockNotificationCenterService()
        sharedKeychainRepository = MockSharedKeychainRepository()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()
        configService.featureFlagsBool[.enableAuthenticatorSync] = true
        subject = DefaultAuthenticatorSyncService(
            application: application,
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

        application = nil
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

    /// Initializing the `AuthenticatorSyncService` when the `enableAuthenticatorSync` feature flag
    /// is turned off should do nothing.
    ///
    func test_init_featureFlagOff() async throws {
        subject = nil
        notificationCenterService.willEnterForegroundSubscribers = 0
        configService.featureFlagsBool[.enableAuthenticatorSync] = false
        subject = DefaultAuthenticatorSyncService(
            application: application,
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
        notificationCenterService.willEnterForegroundSubject.send()
        XCTAssertEqual(notificationCenterService.willEnterForegroundSubscribers, 0)
        // TODO: Test to make sure this does nothing
    }

    /// Initializing the `AuthenticatorSyncService` when the `enableAuthenticatorSync` feature flag
    /// is turned on should do subscribe to foreground notifications.
    ///
    func test_init_featureFlagOn() async throws {
        XCTAssertEqual(notificationCenterService.willEnterForegroundSubscribers, 1)
        notificationCenterService.willEnterForegroundSubject.send()
        // TODO: Test to make sure this does stuff
    }

    /// When the app enters the foreground and the user has subscribed to sync, the
    /// `createAuthenticatorKeyIfNeeded` method successfully creates the sync key
    /// if it is not already present
    ///
    func test_createAuthenticatorKeyIfNeeded_createsKeyWhenNeeded() async throws {
        try sharedKeychainRepository.deleteAuthenticatorKey()
        application.applicationState = .active
        notificationCenterService.willEnterForegroundSubject.send()
        await stateService.addAccount(.fixture(profile: .fixture(userId: "1")))

        try await stateService.setSyncToAuthenticator(true)

        waitFor(sharedKeychainRepository.authenticatorKey != nil)
    }

    /// When the app enters the foreground and the user has subscribed to sync, the
    /// `createAuthenticatorKeyIfNeeded` method successfully retrieves the key in
    /// SharedKeyRepository and doesn't recreate it.
    ///
    func test_createAuthenticatorKeyIfNeeded_keyAlreadyExists() async throws {
    }
}
