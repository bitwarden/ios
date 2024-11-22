import AuthenticationServices
import AuthenticatorBridgeKit
import Foundation
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

class AppProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appModule: MockAppModule!
    var authRepository: MockAuthRepository!
    var authenticatorSyncService: MockAuthenticatorSyncService!
    var autofillCredentialService: MockAutofillCredentialService!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<AppRoute, AppEvent>!
    var errorReporter: MockErrorReporter!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
    var eventService: MockEventService!
    var migrationService: MockMigrationService!
    var notificationCenterService: MockNotificationCenterService!
    var notificationService: MockNotificationService!
    var router: MockRouter<AuthEvent, AuthRoute>!
    var stateService: MockStateService!
    var subject: AppProcessor!
    var syncService: MockSyncService!
    var timeProvider: MockTimeProvider!
    var vaultRepository: MockVaultRepository!
    var vaultTimeoutService: MockVaultTimeoutService!

    var didEnterBackgroundCalled = 0
    var willEnterForegroundCalled = 0

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        router = MockRouter(routeForEvent: { _ in .landing })
        appModule = MockAppModule()
        authRepository = MockAuthRepository()
        authenticatorSyncService = MockAuthenticatorSyncService()
        autofillCredentialService = MockAutofillCredentialService()
        clientService = MockClientService()
        configService = MockConfigService()
        coordinator = MockCoordinator()
        appModule.authRouter = router
        appModule.appCoordinator = coordinator
        errorReporter = MockErrorReporter()
        fido2UserInterfaceHelper = MockFido2UserInterfaceHelper()
        eventService = MockEventService()
        migrationService = MockMigrationService()
        notificationCenterService = MockNotificationCenterService()
        notificationService = MockNotificationService()
        stateService = MockStateService()
        syncService = MockSyncService()
        timeProvider = MockTimeProvider(.currentTime)
        vaultRepository = MockVaultRepository()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = AppProcessor(
            appModule: appModule,
            debugDidEnterBackground: { [weak self] in self?.didEnterBackgroundCalled += 1 },
            debugWillEnterForeground: { [weak self] in self?.willEnterForegroundCalled += 1 },
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                authenticatorSyncService: authenticatorSyncService,
                autofillCredentialService: autofillCredentialService,
                clientService: clientService,
                configService: configService,
                errorReporter: errorReporter,
                eventService: eventService,
                fido2UserInterfaceHelper: fido2UserInterfaceHelper,
                migrationService: migrationService,
                notificationService: notificationService,
                notificationCenterService: notificationCenterService,
                stateService: stateService,
                syncService: syncService,
                vaultRepository: vaultRepository,
                vaultTimeoutService: vaultTimeoutService
            )
        )
        subject.coordinator = coordinator.asAnyCoordinator()
    }

    override func tearDown() {
        super.tearDown()

        appModule = nil
        authRepository = nil
        autofillCredentialService = nil
        clientService = nil
        configService = nil
        coordinator = nil
        errorReporter = nil
        fido2UserInterfaceHelper = nil
        eventService = nil
        migrationService = nil
        notificationCenterService = nil
        notificationService = nil
        router = nil
        stateService = nil
        subject = nil
        syncService = nil
        timeProvider = nil
        vaultRepository = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `init()` subscribes to app background events and logs an error if one occurs when
    /// setting the last active time.
    func test_appBackgrounded_error() {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.setLastActiveTimeError = BitwardenTestError.example

        notificationCenterService.didEnterBackgroundSubject.send()

        waitFor(!errorReporter.errors.isEmpty)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// The user's last active time is updated when the app is backgrounded.
    func test_appBackgrounded_setLastActiveTime() {
        let account: Account = .fixture()
        stateService.activeAccount = account

        vaultTimeoutService.lastActiveTime[account.profile.userId] = .distantPast

        notificationCenterService.didEnterBackgroundSubject.send()
        waitFor(vaultTimeoutService.lastActiveTime[account.profile.userId] != .distantPast)

        let updated = vaultTimeoutService.lastActiveTime[account.profile.userId]

        XCTAssertEqual(timeProvider.presentTime.timeIntervalSince1970, updated!.timeIntervalSince1970, accuracy: 1.0)
    }

    /// `showDebugMenu` will send the correct route to the coordinator.
    @MainActor
    func test_showDebugMenu() {
        subject.showDebugMenu()
        XCTAssertEqual(coordinator.routes.last, .debugMenu)
    }

    /// `didRegister(withToken:)` passes the token to the notification service.
    @MainActor
    func test_didRegister() throws {
        let tokenData = try XCTUnwrap("tokensForFree".data(using: .utf8))

        let task = Task {
            subject.didRegister(withToken: tokenData)
        }

        waitFor(notificationService.registrationTokenData == tokenData)
        task.cancel()
    }

    /// `failedToRegister(_:)` records the error.
    @MainActor
    func test_failedToRegister() {
        subject.failedToRegister(BitwardenTestError.example)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `init()` subscribes to will enter foreground events and handles an active user timeout.
    @MainActor
    func test_init_appForeground_activeUserTimeout() {
        let account1 = Account.fixture(profile: .fixture(userId: "1"))
        let account2 = Account.fixture(profile: .fixture(userId: "2"))
        stateService.activeAccount = account1
        stateService.accounts = [account1, account2]

        vaultTimeoutService.shouldSessionTimeout["1"] = true
        notificationCenterService.willEnterForegroundSubject.send()

        waitFor(!coordinator.events.isEmpty)
        XCTAssertEqual(coordinator.events, [.didTimeout(userId: "1")])
    }

    /// `init()` subscribes to will enter foreground events and logs an error if one occurs when
    /// checking timeouts.
    func test_init_appForeground_error() {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.accounts = [account]
        vaultTimeoutService.shouldSessionTimeoutError = BitwardenTestError.example

        notificationCenterService.willEnterForegroundSubject.send()

        waitFor(!errorReporter.errors.isEmpty)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `init()` subscribes to will enter foreground events and handles an inactive user timeout.
    func test_init_appForeground_inactiveUserTimeout() {
        let account1 = Account.fixture(profile: .fixture(userId: "1"))
        let account2 = Account.fixture(profile: .fixture(userId: "2"))
        stateService.activeAccount = account1
        stateService.accounts = [account1, account2]

        vaultTimeoutService.shouldSessionTimeout["2"] = true
        notificationCenterService.willEnterForegroundSubject.send()

        waitFor(vaultTimeoutService.isClientLocked["2"] == true)
        XCTAssertEqual(vaultTimeoutService.isClientLocked, ["2": true])
    }

    /// `init()` subscribes to will enter foreground events and handles an inactive user timeout
    /// with an logout action.
    func test_init_appForeground_inactiveUserTimeoutLogout() {
        let account1 = Account.fixture(profile: .fixture(userId: "1"))
        let account2 = Account.fixture(profile: .fixture(userId: "2"))
        stateService.activeAccount = account1
        stateService.accounts = [account1, account2]
        authRepository.sessionTimeoutAction["2"] = .logout

        vaultTimeoutService.shouldSessionTimeout["2"] = true
        notificationCenterService.willEnterForegroundSubject.send()

        waitFor(authRepository.logoutCalled)
        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertEqual(authRepository.logoutUserId, "2")
        XCTAssertFalse(authRepository.logoutUserInitiated)
    }

    /// `init()` subscribes to will enter foreground events ands completes the user's autofill setup
    /// process if autofill is enabled and they previously choose to set it up later.
    @MainActor
    func test_init_appForeground_completeAutofillAccountSetup() async throws {
        // The processor checks for autofill completion when entering the foreground. Wait for the
        // initial check to finish when the test starts before continuing.
        try await waitForAsync { self.willEnterForegroundCalled == 1 }

        autofillCredentialService.isAutofillCredentialsEnabled = true
        configService.featureFlagsBool[.nativeCreateAccountFlow] = true
        stateService.activeAccount = .fixture()
        stateService.accounts = [.fixture()]
        stateService.accountSetupAutofill["1"] = .setUpLater

        notificationCenterService.willEnterForegroundSubject.send()
        try await waitForAsync { self.willEnterForegroundCalled == 2 }

        XCTAssertEqual(stateService.accountSetupAutofill, ["1": .complete])
    }

    /// `init()` subscribes to will enter foreground events and handles accountBecameActive if the
    /// never timeout account is unlocked in extension.
    @MainActor
    func test_init_appForeground_checkAccountBecomeActive() async throws {
        // The processor checks for switched accounts when entering the foreground. Wait for the
        // initial check to finish when the test starts before continuing.
        try await waitForAsync { self.willEnterForegroundCalled == 1 }
        let account: Account = .fixture(profile: .fixture(userId: "2"))
        let userId = account.profile.userId
        stateService.activeAccount = account
        authRepository.activeAccount = account
        stateService.didAccountSwitchInExtensionResult = .success(true)
        authRepository.vaultTimeout = [userId: .never]
        authRepository.isLockedResult = .success(true)
        stateService.manuallyLockedAccounts = [userId: false]

        notificationCenterService.willEnterForegroundSubject.send()
        try await waitForAsync { self.willEnterForegroundCalled == 2 }

        XCTAssertEqual(
            coordinator.events.last,
            AppEvent.accountBecameActive(
                account,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// `init()` subscribes to will enter foreground events and logs an error if one occurs while
    /// checking if the active account was changed in an extension.
    @MainActor
    func test_init_appForeground_checkIfExtensionSwitchedAccounts_error() async throws {
        // The processor checks for switched accounts when entering the foreground. Wait for the
        // initial check to finish when the test starts before continuing.
        try await waitForAsync { self.willEnterForegroundCalled == 1 }

        stateService.didAccountSwitchInExtensionResult = .failure(BitwardenTestError.example)

        notificationCenterService.willEnterForegroundSubject.send()
        try await waitForAsync { self.willEnterForegroundCalled == 2 }

        XCTAssertTrue(coordinator.events.isEmpty)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `init()` subscribes to will enter foreground events and doesn't make any navigation changes
    /// if the active account wasn't changed in the extension.
    @MainActor
    func test_init_appForeground_checkIfExtensionSwitchedAccounts_accountNotSwitched() async throws {
        // The processor checks for switched accounts when entering the foreground. Wait for the
        // initial check to finish when the test starts before continuing.
        try await waitForAsync { self.willEnterForegroundCalled == 1 }

        stateService.didAccountSwitchInExtensionResult = .success(false)

        notificationCenterService.willEnterForegroundSubject.send()
        try await waitForAsync { self.willEnterForegroundCalled == 2 }

        XCTAssertTrue(coordinator.events.isEmpty)
    }

    /// `init()` subscribes to will enter foreground events and handles switching accounts if the
    /// active account was changed in the extension.
    @MainActor
    func test_init_appForeground_checkIfExtensionSwitchedAccounts_accountSwitched() async throws {
        // The processor checks for switched accounts when entering the foreground. Wait for the
        // initial check to finish when the test starts before continuing.
        try await waitForAsync { self.willEnterForegroundCalled == 1 }

        stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        stateService.didAccountSwitchInExtensionResult = .success(true)

        notificationCenterService.willEnterForegroundSubject.send()
        try await waitForAsync { self.willEnterForegroundCalled == 2 }

        XCTAssertEqual(coordinator.events, [.switchAccounts(userId: "2", isAutomatic: false)])
    }

    /// `init()` subscribes to will enter foreground events and doesn't check for an account switch
    /// when running in the extension.
    @MainActor
    func test_init_appForeground_checkIfExtensionSwitchedAccounts_inExtension() async throws {
        let delegate = MockAppExtensionDelegate()
        delegate.isInAppExtension = true
        let notificationCenterService = MockNotificationCenterService()
        let stateService = MockStateService()

        var willEnterForegroundCalled = 0
        _ = AppProcessor(
            appExtensionDelegate: delegate,
            appModule: appModule,
            debugWillEnterForeground: { willEnterForegroundCalled += 1 },
            services: ServiceContainer.withMocks(
                notificationCenterService: notificationCenterService,
                stateService: stateService
            )
        )
        try await waitForAsync { willEnterForegroundCalled == 1 }

        stateService.didAccountSwitchInExtensionResult = .success(true)

        notificationCenterService.willEnterForegroundSubject.send()
        try await waitForAsync { willEnterForegroundCalled == 2 }

        XCTAssertTrue(coordinator.events.isEmpty)
    }

    /// `init()` subscribes to will enter foreground events and restarts the app is there's no
    /// active account.
    @MainActor
    func test_init_appForeground_checkIfExtensionSwitchedAccounts_noActiveAccount() async throws {
        // The processor checks for switched accounts when entering the foreground. Wait for the
        // initial check to finish when the test starts before continuing.
        try await waitForAsync { self.willEnterForegroundCalled == 1 }

        stateService.didAccountSwitchInExtensionResult = .success(true)

        notificationCenterService.willEnterForegroundSubject.send()
        try await waitForAsync { self.willEnterForegroundCalled == 2 }

        XCTAssertEqual(coordinator.events, [.didStart])
    }

    /// `init()` sets the `AppProcessor` as the delegate of any necessary services.
    func test_init_setDelegates() {
        XCTAssertIdentical(notificationService.delegate, subject)
        XCTAssertIdentical(syncService.delegate, subject)
    }

    /// `handleAppLinks(URL)` navigates the user based on the input URL.
    @MainActor
    func test_init_handleAppLinks() {
        // swiftlint:disable:next line_length
        let url = URL(string: "https://bitwarden.com/redirect-connector.html#finish-signup?email=example@email.com&token=verificationtoken&fromEmail=true")
        subject.handleAppLinks(incomingURL: url!)

        XCTAssertEqual(coordinator.routes.last, .auth(.completeRegistrationFromAppLink(
            emailVerificationToken: "verificationtoken",
            userEmail: "example@email.com",
            fromEmail: true
        )))
    }

    /// `handleAppLinks(URL)` navigates the user based on the input URL with wrong fromEmail value.
    @MainActor
    func test_init_handleAppLinks_fromEmail_notBool() {
        // swiftlint:disable:next line_length
        let url = URL(string: "https://bitwarden.eu/redirect-connector.html#finish-signup?email=example@email.com&token=verificationtoken&fromEmail=potato")
        subject.handleAppLinks(incomingURL: url!)

        XCTAssertEqual(coordinator.routes.last, .auth(.completeRegistrationFromAppLink(
            emailVerificationToken: "verificationtoken",
            userEmail: "example@email.com",
            fromEmail: true
        )))
    }

    /// `handleAppLinks(URL)` checks error report for `.appLinksInvalidURL`.
    @MainActor
    func test_init_handleAppLinks_invalidURL() {
        // swiftlint:disable:next line_length
        let noPathUrl = URL(string: "https://bitwarden.com/redirect-connector.html#email=example@email.com&token=verificationtoken")
        subject.handleAppLinks(incomingURL: noPathUrl!)
        XCTAssertEqual(errorReporter.errors.last as? AppProcessorError, .appLinksInvalidURL)
        XCTAssertEqual(errorReporter.errors.count, 1)
        errorReporter.errors.removeAll()

        let noParamsUrl = URL(string: "https://bitwarden.com/redirect-connector.html#finish-signup/")
        subject.handleAppLinks(incomingURL: noParamsUrl!)
        XCTAssertEqual(errorReporter.errors.last as? AppProcessorError, .appLinksInvalidURL)
        XCTAssertEqual(errorReporter.errors.count, 1)
        errorReporter.errors.removeAll()

        let invalidHostUrl = URL(string: "/finish-signup?email=example@email.com")
        subject.handleAppLinks(incomingURL: invalidHostUrl!)
        XCTAssertEqual(errorReporter.errors.last as? AppProcessorError, .appLinksInvalidURL)
        XCTAssertEqual(errorReporter.errors.count, 1)
    }

    /// `handleAppLinks(URL)` checks error report for `.appLinksInvalidPath`.
    @MainActor
    func test_init_handleAppLinks_invalidPath() {
        // swiftlint:disable:next line_length
        let url = URL(string: "https://bitwarden.com/redirect-connector.html#not-valid?email=example@email.com&token=verificationtoken&fromEmail=true")
        subject.handleAppLinks(incomingURL: url!)
        XCTAssertEqual(errorReporter.errors.last as? AppProcessorError, .appLinksInvalidPath)
    }

    /// `handleAppLinks(URL)` checks error report for `.appLinksInvalidParametersForPath`.
    @MainActor
    func test_init_handleAppLinks_invalidParametersForPath() {
        var url = URL(
            string: "https://bitwarden.com/redirect-connector.html#finish-signup?token=verificationtoken&fromEmail=true"
        )
        subject.handleAppLinks(incomingURL: url!)
        XCTAssertEqual(errorReporter.errors.last as? AppProcessorError, .appLinksInvalidParametersForPath)
        XCTAssertEqual(errorReporter.errors.count, 1)
        errorReporter.errors.removeAll()

        url = URL(
            string: "https://bitwarden.com/redirect-connector.html#finish-signup?email=example@email.com&fromEmail=true"
        )
        subject.handleAppLinks(incomingURL: url!)
        XCTAssertEqual(errorReporter.errors.last as? AppProcessorError, .appLinksInvalidParametersForPath)
        XCTAssertEqual(errorReporter.errors.count, 1)
        errorReporter.errors.removeAll()

        // swiftlint:disable:next line_length
        url = URL(string: "https://bitwarden.com/redirect-connector.html#finish-signup?email=example@email.com&token=verificationtoken")
        subject.handleAppLinks(incomingURL: url!)
        XCTAssertEqual(errorReporter.errors.last as? AppProcessorError, .appLinksInvalidParametersForPath)
        XCTAssertEqual(errorReporter.errors.count, 1)
        errorReporter.errors.removeAll()
    }

    /// `init()` starts the upload-event timer and attempts to upload events.
    @MainActor
    func test_init_uploadEvents() {
        XCTAssertNotNil(subject.sendEventTimer)
        XCTAssertEqual(subject.sendEventTimer?.isValid, true)
        subject.sendEventTimer?.fire() // Necessary because it's a 5-minute timer
        waitFor(eventService.uploadCalled)
        XCTAssertTrue(eventService.uploadCalled)
    }

    /// `getter:isAutofillingFromList` returns `false` when delegate is not a Fido2 one.
    @MainActor
    func test_isAutofillingFromList_falseNoFido2Delegate() async throws {
        XCTAssertFalse(subject.isAutofillingFromList)
    }

    /// `messageReceived(_:notificationDismissed:notificationTapped)` passes the data to the notification service.
    func test_messageReceived() async {
        let message: [AnyHashable: Any] = ["knock knock": "who's there?"]

        await subject.messageReceived(message)

        XCTAssertEqual(notificationService.messageReceivedMessage?.keys.first, "knock knock")
    }

    /// `onNeedsUserInteraction()` doesn't throw when `appExtensionDelegate` is not a Fido2 one.
    func test_onNeedsUserInteraction_flowWithUserInteraction() async {
        await assertAsyncDoesNotThrow {
            try await subject.onNeedsUserInteraction()
        }
    }

    /// `openUrl(_:)` handles receiving a bitwarden deep link and setting an auth completion route on the
    /// coordinator to handle routing to the account security screen when the vault is unlocked.
    @MainActor
    func test_openUrl_bitwardenAccountSecurity_vaultLocked() async throws {
        await subject.openUrl(.bitwardenAccountSecurity)
        XCTAssertEqual(coordinator.events, [.setAuthCompletionRoute(.tab(.settings(.accountSecurity)))])
    }

    /// `openUrl(_:)` handles receiving a bitwarden deep link and routing to the account security screen.
    @MainActor
    func test_openUrl_bitwardenAccountSecurity_vaultUnlocked() async throws {
        let account = Account.fixture()
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false

        await subject.openUrl(.bitwardenAccountSecurity)
        XCTAssertEqual(coordinator.routes.last, .tab(.settings(.accountSecurity)))
    }

    /// `openUrl(_:)` handles receiving a bitwarden deep link and setting an auth completion route on the
    /// coordinator if the the user's vault is unlocked but will be timing out as the app is
    /// foregrounded.
    @MainActor
    func test_openUrl_bitwardenAccountSecurity_vaultUnlockedTimeout() async throws {
        let account = Account.fixture()
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        vaultTimeoutService.shouldSessionTimeout[account.profile.userId] = true

        await subject.openUrl(.bitwardenAccountSecurity)
        XCTAssertEqual(coordinator.events, [.setAuthCompletionRoute(.tab(.settings(.accountSecurity)))])
    }

    /// `openUrl(_:)` handles receiving a bitwarden deep link and setting an auth completion route on the
    /// coordinator if the the user's vault is unlocked but will be timing out as the app is
    /// foregrounded.
    @MainActor
    func test_openUrl_bitwardenAccountSecurity_vaultUnlockedTimeoutError() async throws {
        let account = Account.fixture()
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        vaultTimeoutService.shouldSessionTimeoutError = BitwardenTestError.example

        await subject.openUrl(.bitwardenAccountSecurity)
        XCTAssertEqual(coordinator.events, [.setAuthCompletionRoute(.tab(.settings(.accountSecurity)))])
    }

    /// `openUrl(_:)` handles receiving a bitwarden Authenticator new item deep link with the vault unlocked and an
    /// invalid item is found. It shows a generic error alert and does not produce a route.
    @MainActor
    func test_openUrl_bitwardenAuthenticatorNewItem_invalidItem() async throws {
        let account = Account.fixture()
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        authenticatorSyncService.tempItem = AuthenticatorBridgeItemDataView(
            accountDomain: nil,
            accountEmail: nil,
            favorite: false,
            id: "",
            name: "",
            totpKey: nil,
            username: nil
        )

        await subject.openUrl(.bitwardenAuthenticatorNewItem)
        XCTAssertEqual(coordinator.alertShown.first,
                       .defaultAlert(title: Localizations.somethingWentWrong,
                                     message: Localizations.unableToMoveTheSelectedItemPleaseTryAgain))
        XCTAssertEqual(coordinator.routes, [])
    }

    /// `openUrl(_:)` handles receiving a bitwarden Authenticator new item deep link when no temporary item is
    /// found in the shared store. It shows a generic error alert and does not produce a route.
    @MainActor
    func test_openUrl_bitwardenAuthenticatorNewItem_noItemFound() async throws {
        let account = Account.fixture()
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        authenticatorSyncService.tempItem = nil

        await subject.openUrl(.bitwardenAuthenticatorNewItem)
        XCTAssertEqual(coordinator.alertShown.first,
                       .defaultAlert(title: Localizations.somethingWentWrong,
                                     message: Localizations.unableToMoveTheSelectedItemPleaseTryAgain))
        XCTAssertEqual(coordinator.routes, [])
    }

    /// `openUrl(_:)` handles receiving a bitwarden Authenticator new item deep link with the vault unlocked and the
    /// item is found, but the item has no TOTP key.  It shows a generic error alert and does not produce a route.
    @MainActor
    func test_openUrl_bitwardenAuthenticatorNewItem_noTotpKey() async throws {
        let account = Account.fixture()
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        authenticatorSyncService.tempItem = AuthenticatorBridgeItemDataView(
            accountDomain: nil,
            accountEmail: nil,
            favorite: false,
            id: "",
            name: "",
            totpKey: nil,
            username: nil
        )

        await subject.openUrl(.bitwardenAuthenticatorNewItem)
        XCTAssertEqual(coordinator.alertShown.first,
                       .defaultAlert(title: Localizations.somethingWentWrong,
                                     message: Localizations.unableToMoveTheSelectedItemPleaseTryAgain))
        XCTAssertEqual(coordinator.routes, [])
    }

    /// `openUrl(_:)` handles receiving a bitwarden Authenticator new item deep link with the vault unlocked and the
    /// item is found.
    @MainActor
    func test_openUrl_bitwardenAuthenticatorNewItem_success() async throws {
        let account = Account.fixture()
        let otpKey: String = .otpAuthUriKeyComplete
        let model = TOTPKeyModel(authenticatorKey: otpKey)
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        authenticatorSyncService.tempItem = AuthenticatorBridgeItemDataView(
            accountDomain: nil,
            accountEmail: nil,
            favorite: false,
            id: "",
            name: "",
            totpKey: otpKey,
            username: nil
        )

        await subject.openUrl(.bitwardenAuthenticatorNewItem)
        XCTAssertEqual(coordinator.routes.last, .tab(.vault(.vaultItemSelection(model))))
    }

    /// `openUrl(_:)` handles receiving a bitwarden link with an invalid path and
    /// silently returns with a no-op.
    @MainActor
    func test_openUrl_bitwardenInvalidPath_failSilently() async throws {
        await subject.openUrl(.bitwardenInvalidPath)

        XCTAssertEqual(coordinator.alertShown, [])
        XCTAssertEqual(coordinator.routes, [])
    }

    /// `openUrl(_:)` handles receiving a bitwarden link with nothing but the scheme (i.e. `bitwarden://`) and
    /// silently returns with a no-op.
    @MainActor
    func test_openUrl_bitwardenSchemeOnly_failSilently() async throws {
        await subject.openUrl(.bitwardenSchemeOnly)

        XCTAssertEqual(coordinator.alertShown, [])
        XCTAssertEqual(coordinator.routes, [])
    }

    /// `openUrl(_:)` handles receiving an OTP deep link and setting an auth completion route on the
    /// coordinator to handle routing to the vault item selection screen when the vault is unlocked.
    @MainActor
    func test_openUrl_otpKey_vaultLocked() async throws {
        let otpKey: String = .otpAuthUriKeyComplete

        try await subject.openUrl(XCTUnwrap(URL(string: otpKey)))

        let model = TOTPKeyModel(authenticatorKey: otpKey)
        XCTAssertEqual(coordinator.events, [.setAuthCompletionRoute(.tab(.vault(.vaultItemSelection(model))))])
    }

    /// `openUrl(_:)` handles receiving an OTP deep link and routing to the vault item selection screen.
    @MainActor
    func test_openUrl_otpKey_vaultUnlocked() async throws {
        let account = Account.fixture()
        let otpKey: String = .otpAuthUriKeyComplete
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false

        try await subject.openUrl(XCTUnwrap(URL(string: otpKey)))

        let model = TOTPKeyModel(authenticatorKey: otpKey)
        XCTAssertEqual(coordinator.routes.last, .tab(.vault(.vaultItemSelection(model))))
    }

    /// `openUrl(_:)` handles receiving an OTP deep link and setting an auth completion route on the
    /// coordinator if the the user's vault is unlocked but will be timing out as the app is
    /// foregrounded.
    @MainActor
    func test_openUrl_otpKey_vaultUnlockedTimeout() async throws {
        let account = Account.fixture()
        let otpKey: String = .otpAuthUriKeyComplete
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        vaultTimeoutService.shouldSessionTimeout[account.profile.userId] = true

        try await subject.openUrl(XCTUnwrap(URL(string: otpKey)))

        let model = TOTPKeyModel(authenticatorKey: otpKey)
        XCTAssertEqual(coordinator.events, [.setAuthCompletionRoute(.tab(.vault(.vaultItemSelection(model))))])
    }

    /// `openUrl(_:)` handles receiving an OTP deep link and setting an auth completion route on the
    /// coordinator if the the user's vault is unlocked but will be timing out as the app is
    /// foregrounded.
    @MainActor
    func test_openUrl_otpKey_vaultUnlockedTimeoutError() async throws {
        let account = Account.fixture()
        let otpKey: String = .otpAuthUriKeyComplete
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        vaultTimeoutService.shouldSessionTimeoutError = BitwardenTestError.example

        try await subject.openUrl(XCTUnwrap(URL(string: otpKey)))

        let model = TOTPKeyModel(authenticatorKey: otpKey)
        XCTAssertEqual(coordinator.events, [.setAuthCompletionRoute(.tab(.vault(.vaultItemSelection(model))))])
    }

    /// `openUrl(_:)` handles receiving an non OTP deep link and silently returns with a no-op.
    @MainActor
    func test_openUrl_nonOtpKey_failSilently() async throws {
        try await subject.openUrl(XCTUnwrap(URL(string: "bitwarden://")))

        XCTAssertEqual(coordinator.alertShown, [])
        XCTAssertEqual(coordinator.routes, [])
    }

    /// `openUrl(_:)` handles receiving an OTP deep link if the URL isn't an OTP key.
    @MainActor
    func test_openUrl_otpKey_invalid() async throws {
        let otpKey: String = .otpAuthUriKeyNoSecret
        try await subject.openUrl(XCTUnwrap(URL(string: otpKey)))

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(coordinator.routes, [])
    }

    /// `provideCredential(for:)` returns the credential with the specified identifier.
    func test_provideCredential() async throws {
        let credential = ASPasswordCredential(user: "user@bitwarden.com", password: "password123")
        autofillCredentialService.provideCredentialPasswordCredential = credential

        let providedCredential = try await subject.provideCredential(for: "1")
        XCTAssertEqual(providedCredential.user, "user@bitwarden.com")
        XCTAssertEqual(providedCredential.password, "password123")
    }

    /// `provideCredential(for:)` throws an error if one occurs.
    func test_provideCredential_error() async throws {
        autofillCredentialService.provideCredentialError = ASExtensionError(.userInteractionRequired)

        await assertAsyncThrows(error: ASExtensionError(.userInteractionRequired)) {
            _ = try await subject.provideCredential(for: "1")
        }
    }

    /// `removeMasterPassword(organizationName:)` notifies the coordinator to show the remove
    /// master password screen.
    @MainActor
    func test_removeMasterPassword() {
        coordinator.isLoadingOverlayShowing = true

        subject.removeMasterPassword(organizationName: "Example Org")

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.routes, [.auth(.removeMasterPassword(organizationName: "Example Org"))])
    }

    /// `removeMasterPassword(organizationName:)` doesn't show the remove master password screen in
    /// the extension.
    @MainActor
    func test_removeMasterPassword_extension() {
        let delegate = MockAppExtensionDelegate()
        let subject = AppProcessor(
            appExtensionDelegate: delegate,
            appModule: appModule,
            services: ServiceContainer.withMocks()
        )

        subject.removeMasterPassword(organizationName: "Example Org")

        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `repromptForCredentialIfNecessary(for:)` reprompts the user for their master password if
    /// reprompt is enabled for the cipher.
    @MainActor
    func test_repromptForCredentialIfNecessary() throws {
        vaultRepository.repromptRequiredForCipherResult = .success(true)

        var masterPasswordValidated: Bool?
        let expectation = expectation(description: #function)
        Task {
            try await subject.repromptForCredentialIfNecessary(for: "1") { validated in
                masterPasswordValidated = validated
                expectation.fulfill()
            }
        }
        waitFor(!coordinator.alertShown.isEmpty)

        XCTAssertEqual(coordinator.alertShown.count, 1)
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .masterPasswordPrompt { _ in })
        var textField = try XCTUnwrap(alert.alertTextFields.first)
        textField = AlertTextField(id: "password", text: "password")
        let submitAction = try XCTUnwrap(alert.alertActions.first(where: { $0.title == Localizations.submit }))
        Task {
            await submitAction.handler?(submitAction, [textField])
        }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(masterPasswordValidated, true)
    }

    /// `repromptForCredentialIfNecessary(for:)` logs the error if one occurs.
    @MainActor
    func test_repromptForCredentialIfNecessary_error() throws {
        authRepository.validatePasswordResult = .failure(BitwardenTestError.example)
        vaultRepository.repromptRequiredForCipherResult = .success(true)

        var masterPasswordValidated: Bool?
        let expectation = expectation(description: #function)
        Task {
            try await subject.repromptForCredentialIfNecessary(for: "1") { validated in
                masterPasswordValidated = validated
                expectation.fulfill()
            }
        }
        waitFor(!coordinator.alertShown.isEmpty)

        XCTAssertEqual(coordinator.alertShown.count, 1)
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .masterPasswordPrompt { _ in })
        Task {
            try await alert.tapAction(title: Localizations.submit)
        }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(masterPasswordValidated, false)
    }

    /// `repromptForCredentialIfNecessary(for:)` displays an alert if the user enters an invalid
    /// password into the master password reprompt alert.
    @MainActor
    func test_repromptForCredentialIfNecessary_invalidPassword() throws {
        authRepository.validatePasswordResult = .success(false)
        vaultRepository.repromptRequiredForCipherResult = .success(true)

        var masterPasswordValidated: Bool?
        let expectation = expectation(description: #function)
        Task {
            try await subject.repromptForCredentialIfNecessary(for: "1") { validated in
                masterPasswordValidated = validated
                expectation.fulfill()
            }
        }
        waitFor(!coordinator.alertShown.isEmpty)

        XCTAssertEqual(coordinator.alertShown.count, 1)
        var alert = try XCTUnwrap(coordinator.alertShown.last)
        Task {
            try await alert.tapAction(title: Localizations.submit)
        }

        waitFor(coordinator.alertShown.count == 2)
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .defaultAlert(title: Localizations.invalidMasterPassword))
        Task {
            try await alert.tapAction(title: Localizations.ok)
        }
        coordinator.alertOnDismissed?()

        waitForExpectations(timeout: 1)

        XCTAssertEqual(masterPasswordValidated, false)
    }

    /// `repromptForCredentialIfNecessary(for:)` calls the completion handler if reprompt isn't
    /// required for the cipher.
    func test_repromptForCredentialIfNecessary_repromptNotRequired() async throws {
        vaultRepository.repromptRequiredForCipherResult = .success(false)

        var masterPasswordValidated: Bool?
        try await subject.repromptForCredentialIfNecessary(for: "1") { validated in
            masterPasswordValidated = validated
        }

        XCTAssertEqual(masterPasswordValidated, false)
    }

    /// `routeToLanding(_:)` navigates to show the landing view.
    @MainActor
    func test_routeToLanding() async {
        await subject.routeToLanding()
        XCTAssertEqual(coordinator.routes.last, .auth(.landing))
    }

    /// `securityStampChanged(userId:)` logs the user out and notifies the coordinator.
    @MainActor
    func test_securityStampChanged() async {
        coordinator.isLoadingOverlayShowing = true

        await subject.securityStampChanged(userId: "1")

        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertEqual(authRepository.logoutUserId, "1")
        XCTAssertFalse(authRepository.logoutUserInitiated)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.events, [.didLogout(userId: "1", userInitiated: false)])
    }

    /// `showLoginRequest(_:)` navigates to show the login request view.
    @MainActor
    func test_showLoginRequest() {
        subject.showLoginRequest(.fixture())
        XCTAssertEqual(coordinator.routes.last, .loginRequest(.fixture()))
    }

    /// `start(navigator:)` builds the AppCoordinator and navigates to the initial route if provided.
    @MainActor
    func test_start_initialRoute() async {
        let rootNavigator = MockRootNavigator()

        await subject.start(
            appContext: .mainApp,
            initialRoute: .extensionSetup(.extensionActivation(type: .appExtension)),
            navigator: rootNavigator,
            window: nil
        )

        waitFor(!coordinator.routes.isEmpty)

        XCTAssertTrue(appModule.appCoordinator.isStarted)
        XCTAssertEqual(
            appModule.appCoordinator.routes,
            [.extensionSetup(.extensionActivation(type: .appExtension))]
        )
        XCTAssertEqual(migrationService.didPerformMigrations, true)
    }

    /// `start(navigator:)` builds the AppCoordinator and navigates to the `.didStart` route.
    @MainActor
    func test_start_authRoute() async {
        let rootNavigator = MockRootNavigator()

        await subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        waitFor(!coordinator.events.isEmpty)

        XCTAssertTrue(appModule.appCoordinator.isStarted)
        XCTAssertEqual(appModule.appCoordinator.events, [.didStart])
        XCTAssertEqual(migrationService.didPerformMigrations, true)
    }

    /// `start(navigator:)` doesn't complete the accounts autofill setup when running in an app extension.
    @MainActor
    func test_start_completeAutofillAccountSetupIfEnabled_appExtension() async throws {
        let delegate = MockAppExtensionDelegate()
        delegate.isInAppExtension = true
        var willEnterForegroundCalled = 0
        let subject = AppProcessor(
            appExtensionDelegate: delegate,
            appModule: appModule,
            debugWillEnterForeground: { willEnterForegroundCalled += 1 },
            services: ServiceContainer.withMocks(
                autofillCredentialService: autofillCredentialService,
                configService: configService,
                stateService: stateService
            )
        )
        try await waitForAsync { willEnterForegroundCalled == 1 }

        autofillCredentialService.isAutofillCredentialsEnabled = true
        configService.featureFlagsBool[.nativeCreateAccountFlow] = true
        stateService.activeAccount = .fixture()
        stateService.accounts = [.fixture()]
        stateService.accountSetupAutofill["1"] = .setUpLater

        let rootNavigator = MockRootNavigator()
        await subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertEqual(stateService.accountSetupAutofill, ["1": .setUpLater])
    }

    /// `start(navigator:)` doesn't complete the accounts autofill setup if autofill is disabled.
    @MainActor
    func test_start_completeAutofillAccountSetupIfEnabled_autofillDisabled() async {
        autofillCredentialService.isAutofillCredentialsEnabled = false
        configService.featureFlagsBool[.nativeCreateAccountFlow] = true
        stateService.activeAccount = .fixture()
        stateService.accounts = [.fixture()]
        stateService.accountSetupAutofill["1"] = .setUpLater

        let rootNavigator = MockRootNavigator()
        await subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertEqual(stateService.accountSetupAutofill, ["1": .setUpLater])
    }

    /// `start(navigator:)` doesn't complete the accounts autofill setup if the native create
    /// account flow feature flag is disabled.
    @MainActor
    func test_start_completeAutofillAccountSetupIfEnabled_featureFlagDisabled() async {
        autofillCredentialService.isAutofillCredentialsEnabled = true
        configService.featureFlagsBool[.nativeCreateAccountFlow] = false
        stateService.activeAccount = .fixture()
        stateService.accounts = [.fixture()]
        stateService.accountSetupAutofill["1"] = .setUpLater

        let rootNavigator = MockRootNavigator()
        await subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertEqual(stateService.accountSetupAutofill, ["1": .setUpLater])
    }

    /// `start(navigator:)` logs an error if one occurs while updating the account's autofill setup.
    @MainActor
    func test_start_completeAutofillAccountSetupIfEnabled_error() async throws {
        // The processor checks for autofill completion when entering the foreground. Wait for the
        // initial check to finish when the test starts before continuing.
        try await waitForAsync { self.willEnterForegroundCalled == 1 }

        autofillCredentialService.isAutofillCredentialsEnabled = true
        configService.featureFlagsBool[.nativeCreateAccountFlow] = true
        stateService.accounts = [.fixture()]
        stateService.accountSetupAutofill["1"] = .setUpLater
        stateService.accountSetupAutofillError = BitwardenTestError.example

        let rootNavigator = MockRootNavigator()
        await subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(stateService.accountSetupAutofill, ["1": .setUpLater])
    }

    /// `start(navigator:)` doesn't update the user's autofill setup progress if they have no
    /// current progress recorded.
    @MainActor
    func test_start_completeAutofillAccountSetupIfEnabled_noProgress() async {
        autofillCredentialService.isAutofillCredentialsEnabled = true
        configService.featureFlagsBool[.nativeCreateAccountFlow] = true
        stateService.activeAccount = .fixture()
        stateService.accounts = [.fixture()]

        let rootNavigator = MockRootNavigator()
        await subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertTrue(stateService.accountSetupAutofill.isEmpty)
    }

    /// `start(navigator:)` completes the user's autofill setup progress if autofill is enabled and
    /// they previously choose to set it up later.
    @MainActor
    func test_start_completeAutofillAccountSetupIfEnabled_success() async throws {
        // The processor checks for autofill completion when entering the foreground. Wait for the
        // initial check to finish when the test starts before continuing.
        try await waitForAsync { self.willEnterForegroundCalled == 1 }

        autofillCredentialService.isAutofillCredentialsEnabled = true
        configService.featureFlagsBool[.nativeCreateAccountFlow] = true
        stateService.activeAccount = .fixture()
        stateService.accounts = [.fixture()]
        stateService.accountSetupAutofill["1"] = .setUpLater

        let rootNavigator = MockRootNavigator()
        await subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertEqual(stateService.accountSetupAutofill, ["1": .complete])
    }

    /// `unlockVaultWithNeverlockKey()` unlocks it calling the auth repository.
    func test_unlockVaultWithNeverlockKey() async throws {
        try await subject.unlockVaultWithNeverlockKey()

        XCTAssertTrue(authRepository.unlockVaultWithNeverlockKeyCalled)
    }

    /// `unlockVaultWithNeverlockKey()` throws because auth repository call throws.
    func test_unlockVaultWithNeverlockKey_throws() async throws {
        authRepository.unlockVaultWithNeverlockResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.unlockVaultWithNeverlockKey()
        }
    }
}
