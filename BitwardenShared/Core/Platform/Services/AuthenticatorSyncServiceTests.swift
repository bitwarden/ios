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

    /// `auth(for:)` returns a new `ClientAuthProtocol` for every user.
    func test_auth() async throws {}
}
