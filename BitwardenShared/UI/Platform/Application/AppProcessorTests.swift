import AuthenticationServices
import AuthenticatorBridgeKit
import BitwardenKitMocks
import BitwardenResources
import Foundation
import TestHelpers
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

class AppProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appIntentMediator: MockAppIntentMediator!
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
    var pendingAppIntentActionMediator: MockPendingAppIntentActionMediator!
    var policyService: MockPolicyService!
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

    override func setUp() { // swiftlint:disable:this function_body_length
        super.setUp()

        router = MockRouter(routeForEvent: { _ in .landing })
        appIntentMediator = MockAppIntentMediator()
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
        pendingAppIntentActionMediator = MockPendingAppIntentActionMediator()
        policyService = MockPolicyService()
        stateService = MockStateService()
        syncService = MockSyncService()
        timeProvider = MockTimeProvider(.currentTime)
        vaultRepository = MockVaultRepository()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = AppProcessor(
            appIntentMediator: appIntentMediator,
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
                pendingAppIntentActionMediator: pendingAppIntentActionMediator,
                policyService: policyService,
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
        pendingAppIntentActionMediator = nil
        policyService = nil
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
    @MainActor
    func test_appBackgrounded_error() {
        stateService.activeAccount = .fixture()
        vaultTimeoutService.setLastActiveTimeError = BitwardenTestError.example

        notificationCenterService.didEnterBackgroundSubject.send()

        waitFor(!errorReporter.errors.isEmpty)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// The user's last active time is updated when the app is backgrounded.
    @MainActor
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
        // Wait for the checkSessionTimeouts method to be called
        waitFor(authRepository.checkSessionTimeoutCalled)

        // Simulate calling the handleActiveUser closure
        if let handleActiveUserClosure = authRepository.handleActiveUserClosure {
            Task {
                await handleActiveUserClosure("1")
            }
        }
        waitFor(!coordinator.events.isEmpty)
        XCTAssertEqual(coordinator.events, [.didTimeout(userId: "1")])
    }

    /// `init()` subscribes to will enter foreground events ands completes the user's autofill setup
    /// process if autofill is enabled and they previously choose to set it up later.
    @MainActor
    func test_init_appForeground_completeAutofillAccountSetup() async throws {
        // The processor checks for autofill completion when entering the foreground. Wait for the
        // initial check to finish when the test starts before continuing.
        try await waitForAsync { self.willEnterForegroundCalled == 1 }

        autofillCredentialService.isAutofillCredentialsEnabled = true
        stateService.activeAccount = .fixture()
        stateService.accounts = [.fixture()]
        stateService.accountSetupAutofill["1"] = .setUpLater

        notificationCenterService.willEnterForegroundSubject.send()
        try await waitForAsync { self.willEnterForegroundCalled == 2 }

        XCTAssertEqual(stateService.accountSetupAutofill, ["1": .complete])
    }

    /// `init()` subscribes to will enter foreground events and handles accountBecameActive if the
    /// never timeout account is unlocked in extension and there is no pending `AppIntent` actions.
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

    /// `init()` subscribes to will enter foreground events and handles accountBecameActive if the
    /// never timeout account is unlocked in extension and there is an empty collection of pending `AppIntent` actions.
    @MainActor
    func test_init_appForeground_checkAccountBecomeActivePendingAppIntentActionsEmpty() async throws {
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
        stateService.pendingAppIntentActions = []

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

    /// `init()` subscribes to will enter foreground events and doesn't handle accountBecameActive if the
    /// never timeout account is unlocked in extension but there's a pending `.lockAll` `AppIntent`.
    @MainActor
    func test_init_appForeground_checkAccountBecomeActiveEventDoesntHappenWhenPendingLockAllAppIntent() async throws {
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
        stateService.pendingAppIntentActions = [.lockAll]

        notificationCenterService.willEnterForegroundSubject.send()
        try await waitForAsync { self.willEnterForegroundCalled == 2 }

        XCTAssertNotEqual(
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

    /// `init()` subscribes to will pending App Intent actions publisher and handles an active user timeout.
    @MainActor
    func test_init_pendingAppIntentActionsTask() {
        // Wait and reset for the first publisher default values which are `nil`.
        waitFor(pendingAppIntentActionMediator.executePendingAppIntentActionsCalled)
        pendingAppIntentActionMediator.executePendingAppIntentActionsCalled = false

        stateService.pendingAppIntentActionsSubject.send([.lockAll])
        waitFor(pendingAppIntentActionMediator.executePendingAppIntentActionsCalled)
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

    /// `onPendingAppIntentActionSuccess(_:data:)` handles event `.accountBecameActive` when
    /// pending app intent action is `.lockAll` and `data` is an account.
    @MainActor
    func test_onPendingAppIntentActionSuccess_lockAll() async {
        let account = Account.fixture()
        await subject.onPendingAppIntentActionSuccess(.lockAll, data: account)
        XCTAssertEqual(
            coordinator.events,
            [
                .accountBecameActive(
                    account,
                    attemptAutomaticBiometricUnlock: true,
                    didSwitchAccountAutomatically: false
                ),
            ]
        )
    }

    /// `onPendingAppIntentActionSuccess(_:data:)` doesn't handle event `.accountBecameActive` when
    /// pending app intent action is `.lockAll` and `data` is `nil`.
    @MainActor
    func test_onPendingAppIntentActionSuccess_lockAllNoData() async {
        await subject.onPendingAppIntentActionSuccess(.lockAll, data: nil)
        XCTAssertTrue(coordinator.events.isEmpty)
    }

    /// `onPendingAppIntentActionSuccess(_:data:)` doesn't handle event `.accountBecameActive` when
    /// pending app intent action is `.lockAll` and `data` is not an `Account`.
    @MainActor
    func test_onPendingAppIntentActionSuccess_lockAllDataNoAccount() async {
        await subject.onPendingAppIntentActionSuccess(.lockAll, data: "noAccount")
        XCTAssertTrue(coordinator.events.isEmpty)
    }

    /// `onPendingAppIntentActionSuccess(_:data:)` handles event `.didLogOutAll` when
    /// pending app intent action is `.logOutAll`.
    @MainActor
    func test_onPendingAppIntentActionSuccess_logOutAll() async {
        await subject.onPendingAppIntentActionSuccess(.logOutAll, data: nil)
        XCTAssertEqual(
            coordinator.events,
            [.didLogout(userId: nil, userInitiated: true)]
        )
    }

    /// `onPendingAppIntentActionSuccess(_:data:)` sets `setAuthCompletionRoute` as the generator when
    /// pending app intent action is `.openGenerator` and the vault is locked.
    @MainActor
    func test_onPendingAppIntentActionSuccess_openGeneratorVaultLocked() async throws {
        await subject.onPendingAppIntentActionSuccess(.openGenerator, data: nil)
        XCTAssertEqual(coordinator.events, [.setAuthCompletionRoute(.tab(.generator(.generator())))])
    }

    /// `onPendingAppIntentActionSuccess(_:data:)` handles navigation to the generator screen when
    /// pending app intent action is `.openGenerator` and the vault is unlocked.
    @MainActor
    func test_onPendingAppIntentActionSuccess_openGeneratorVaultUnlocked() async throws {
        let account = Account.fixture()
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false

        await subject.onPendingAppIntentActionSuccess(.openGenerator, data: nil)
        XCTAssertEqual(coordinator.routes.last, .tab(.generator(.generator())))
    }

    /// `onPendingAppIntentActionSuccess(_:data:)` handles receiving a pending AppIntent action for  `.openGenerator`
    /// and setting an auth completion route on the coordinator if the the user's vault is unlocked
    /// but will be timing out as the app is foregrounded.
    @MainActor
    func test_onPendingAppIntentActionSuccess_openGeneratorVaultUnlockedTimeout() async throws {
        let account = Account.fixture()
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        vaultTimeoutService.shouldSessionTimeout[account.profile.userId] = true

        await subject.onPendingAppIntentActionSuccess(.openGenerator, data: nil)
        XCTAssertEqual(coordinator.events, [.setAuthCompletionRoute(.tab(.generator(.generator())))])
    }

    /// `onPendingAppIntentActionSuccess(_:data:)` handles receiving a pending AppIntent action for  `.openGenerator`
    /// and setting an auth completion route on the coordinator if the the user's vault is unlocked
    /// but checking timing out as throws an error.
    @MainActor
    func test_onPendingAppIntentActionSuccess_openGeneratorVaultUnlockedTimeoutError() async throws {
        let account = Account.fixture()
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        vaultTimeoutService.shouldSessionTimeoutError = BitwardenTestError.example

        await subject.onPendingAppIntentActionSuccess(.openGenerator, data: nil)
        XCTAssertEqual(coordinator.events, [.setAuthCompletionRoute(.tab(.generator(.generator())))])
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

    /// `provideOTPCredential(for:repromptPasswordValidated:)` returns the credential with the specified identifier.
    @available(iOS 18.0, *)
    func test_provideOTPCredential() async throws {
        let credential = ASOneTimeCodeCredential(code: "123")
        autofillCredentialService.provideOTPCredentialResult = .success(credential)

        let providedCredential = try await subject.provideOTPCredential(for: "1")
        XCTAssertEqual(providedCredential.code, "123")
    }

    /// `provideOTPCredential(for:repromptPasswordValidated:)` throws an error if one occurs.
    @available(iOS 18.0, *)
    func test_provideOTPCredential_error() async throws {
        autofillCredentialService.provideOTPCredentialResult = .failure(ASExtensionError(.userInteractionRequired))

        await assertAsyncThrows(error: ASExtensionError(.userInteractionRequired)) {
            _ = try await subject.provideOTPCredential(for: "1")
        }
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
        stateService.accounts = [.fixture()]
        stateService.accountSetupAutofill["1"] = .setUpLater
        stateService.accountSetupAutofillError = BitwardenTestError.example

        let rootNavigator = MockRootNavigator()
        await subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(stateService.accountSetupAutofill, ["1": .setUpLater])
    }

    /// `start(navigator:)` doesn't log an error if there's no accounts.
    @MainActor
    func test_start_completeAutofillAccountSetupIfEnabled_noAccounts() async throws {
        autofillCredentialService.isAutofillCredentialsEnabled = true

        let rootNavigator = MockRootNavigator()
        await subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertTrue(stateService.accountSetupAutofill.isEmpty)
    }

    /// `start(navigator:)` doesn't update the user's autofill setup progress if they have no
    /// current progress recorded.
    @MainActor
    func test_start_completeAutofillAccountSetupIfEnabled_noProgress() async {
        autofillCredentialService.isAutofillCredentialsEnabled = true
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
        stateService.activeAccount = .fixture()
        stateService.accounts = [.fixture()]
        stateService.accountSetupAutofill["1"] = .setUpLater

        let rootNavigator = MockRootNavigator()
        await subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertEqual(stateService.accountSetupAutofill, ["1": .complete])
    }

    /// `switchAccountsForLoginRequest(to:showAlert:)` has the coordinator switch to the specified
    /// account without showing a confirmation alert.
    @MainActor
    func test_switchAccountsForLoginRequest() async {
        await subject.switchAccountsForLoginRequest(to: .fixture(), showAlert: false)

        XCTAssertEqual(coordinator.events, [.switchAccounts(userId: "1", isAutomatic: false)])
    }

    /// `switchAccountsForLoginRequest(to:showAlert:)` shows an alert to confirm the user wants to
    /// switch to the specified account and then has the coordinator switch accounts.
    @MainActor
    func test_switchAccountsForLoginRequest_showAlert() async throws {
        let account = Account.fixture()
        await subject.switchAccountsForLoginRequest(to: account, showAlert: true)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(
            alert,
            .confirmation(
                title: Localizations.logInRequested,
                message: Localizations.loginAttemptFromXDoYouWantToSwitchToThisAccount(account.profile.email),
                confirmationHandler: {}
            )
        )

        try await alert.tapAction(title: Localizations.cancel)
        XCTAssertTrue(coordinator.events.isEmpty)

        try await alert.tapAction(title: Localizations.yes)
        XCTAssertEqual(coordinator.events, [.switchAccounts(userId: account.profile.userId, isAutomatic: false)])
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

    // MARK: SyncServiceDelegate

    /// `onFetchSyncSucceeded(userId:)` clear the unlock user pins when it has performed sync after login
    /// for the first time and `.removeUnlockWithPin` policy is enabled.
    func test_onFetchSyncSucceeded_clearPins() async throws {
        await stateService.addAccount(.fixture())
        stateService.pinProtectedUserKeyValue["1"] = "pin"
        stateService.encryptedPinByUserId["1"] = "encPin"
        stateService.accountVolatileData["1"] = AccountVolatileData(pinProtectedUserKey: "pin")
        stateService.hasPerformedSyncAfterLogin["1"] = false
        policyService.policyAppliesToUserResult[.removeUnlockWithPin] = true

        await subject.onFetchSyncSucceeded(userId: "1")

        XCTAssertNil(stateService.pinProtectedUserKeyValue["1"])
        XCTAssertNil(stateService.encryptedPinByUserId["1"])
        XCTAssertNil(stateService.accountVolatileData["1"])
    }

    /// `onFetchSyncSucceeded(userId:)` doesn't clear the unlock user pins when it has performed sync after login
    /// for the first time and `.removeUnlockWithPin` policy is disabled.
    func test_onFetchSyncSucceeded_doesNotClearPinsWhenRemoveUnlockWithPinPolicyDisabled() async throws {
        await stateService.addAccount(.fixture())
        stateService.pinProtectedUserKeyValue["1"] = "pin"
        stateService.encryptedPinByUserId["1"] = "encPin"
        stateService.accountVolatileData["1"] = AccountVolatileData(pinProtectedUserKey: "pin")
        stateService.hasPerformedSyncAfterLogin["1"] = false
        policyService.policyAppliesToUserResult[.removeUnlockWithPin] = false

        await subject.onFetchSyncSucceeded(userId: "1")

        XCTAssertNotNil(stateService.pinProtectedUserKeyValue["1"])
        XCTAssertNotNil(stateService.encryptedPinByUserId["1"])
        XCTAssertNotNil(stateService.accountVolatileData["1"])
        XCTAssertTrue(stateService.hasPerformedSyncAfterLogin["1"] == true)
    }

    /// `onFetchSyncSucceeded(userId:)` doesn't clear the unlock user pins when it's not the first time it has
    /// performed sync after login.
    func test_onFetchSyncSucceeded_doesNotClearPinsWhenNotFirstTimeSyncAfterLogin() async throws {
        await stateService.addAccount(.fixture())
        stateService.pinProtectedUserKeyValue["1"] = "pin"
        stateService.encryptedPinByUserId["1"] = "encPin"
        stateService.accountVolatileData["1"] = AccountVolatileData(pinProtectedUserKey: "pin")
        stateService.hasPerformedSyncAfterLogin["1"] = true

        await subject.onFetchSyncSucceeded(userId: "1")

        XCTAssertTrue(policyService.policyAppliesToUserPolicies.isEmpty)
        XCTAssertNotNil(stateService.pinProtectedUserKeyValue["1"])
        XCTAssertNotNil(stateService.encryptedPinByUserId["1"])
        XCTAssertNotNil(stateService.accountVolatileData["1"])
    }

    /// `onFetchSyncSucceeded(userId:)` doesn't do anything when `getHasPerformedSyncAfterLogin(userId:)` throws.
    func test_onFetchSyncSucceeded_getHasPerformedSyncAfterLoginThrows() async throws {
        stateService.pinProtectedUserKeyValue["1"] = "pin"
        stateService.encryptedPinByUserId["1"] = "encPin"
        stateService.accountVolatileData["1"] = AccountVolatileData(pinProtectedUserKey: "pin")
        stateService.getHasPerformedSyncAfterLoginError = BitwardenTestError.example

        await subject.onFetchSyncSucceeded(userId: "1")

        XCTAssertTrue(policyService.policyAppliesToUserPolicies.isEmpty)
        XCTAssertNotNil(stateService.pinProtectedUserKeyValue["1"])
        XCTAssertNotNil(stateService.encryptedPinByUserId["1"])
        XCTAssertNotNil(stateService.accountVolatileData["1"])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `onFetchSyncSucceeded(userId:)` doesn't do anything when
    /// `setHasPerformedSyncAfterLogin(hasBeenPerformed:, userId:)` throws.
    func test_onFetchSyncSucceeded_setHasPerformedSyncAfterLoginThrows() async throws {
        stateService.pinProtectedUserKeyValue["1"] = "pin"
        stateService.encryptedPinByUserId["1"] = "encPin"
        stateService.accountVolatileData["1"] = AccountVolatileData(pinProtectedUserKey: "pin")
        stateService.setHasPerformedSyncAfterLoginError = BitwardenTestError.example

        await subject.onFetchSyncSucceeded(userId: "1")

        XCTAssertTrue(policyService.policyAppliesToUserPolicies.isEmpty)
        XCTAssertNotNil(stateService.pinProtectedUserKeyValue["1"])
        XCTAssertNotNil(stateService.encryptedPinByUserId["1"])
        XCTAssertNotNil(stateService.accountVolatileData["1"])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `onFetchSyncSucceeded(userId:)` doesn't clear pins when
    /// `clearPins(userId:)` throws.
    func test_onFetchSyncSucceeded_clearPinsThrows() async throws {
        stateService.pinProtectedUserKeyValue["1"] = "pin"
        stateService.encryptedPinByUserId["1"] = "encPin"
        stateService.accountVolatileData["1"] = AccountVolatileData(pinProtectedUserKey: "pin")
        stateService.hasPerformedSyncAfterLogin["1"] = false
        policyService.policyAppliesToUserResult[.removeUnlockWithPin] = true
        stateService.activeAccount = nil

        await subject.onFetchSyncSucceeded(userId: "1")

        XCTAssertNotNil(stateService.pinProtectedUserKeyValue["1"])
        XCTAssertNotNil(stateService.encryptedPinByUserId["1"])
        XCTAssertNotNil(stateService.accountVolatileData["1"])
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `removeMasterPassword(organizationName:)` notifies the coordinator to show the remove
    /// master password screen.
    @MainActor
    func test_removeMasterPassword() {
        coordinator.isLoadingOverlayShowing = true

        subject.removeMasterPassword(
            organizationName: "Example Org",
            organizationId: "ORG_ID",
            keyConnectorUrl: "https://example.com"
        )

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(
            coordinator.routes,
            [
                .auth(.removeMasterPassword(
                    organizationName: "Example Org",
                    organizationId: "ORG_ID",
                    keyConnectorUrl: "https://example.com"
                )),
            ]
        )
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

        subject.removeMasterPassword(
            organizationName: "Example Org",
            organizationId: "ORG_ID",
            keyConnectorUrl: "https://example.com"
        )

        XCTAssertTrue(coordinator.routes.isEmpty)
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

    /// `securityStampChanged(userId:)` throws logging the user out which is logged and notifies the coordinator.
    @MainActor
    func test_securityStampChanged_throwsLogging() async {
        coordinator.isLoadingOverlayShowing = true
        authRepository.logoutResult = .failure(BitwardenTestError.example)

        await subject.securityStampChanged(userId: "1")

        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.events, [.didLogout(userId: "1", userInitiated: false)])
    }

    /// `onRefreshTokenError(error:)` logs the user out and notifies the coordinator when error is `.invalidGrant`.
    @MainActor
    func test_onRefreshTokenError_logOutInvalidGrant() async throws {
        coordinator.isLoadingOverlayShowing = true

        try await subject.onRefreshTokenError(error: IdentityTokenRefreshRequestError.invalidGrant)

        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertEqual(authRepository.logoutUserId, nil)
        XCTAssertFalse(authRepository.logoutUserInitiated)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.events, [.didLogout(userId: nil, userInitiated: false)])
    }

    /// `onRefreshTokenError(error:)` throws logging the user out which is logged and notifies the coordinator
    /// when error is `.invalidGrant`.
    @MainActor
    func test_onRefreshTokenError_logOutInvalidGrantThrowsLogging() async throws {
        coordinator.isLoadingOverlayShowing = true
        authRepository.logoutResult = .failure(BitwardenTestError.example)

        try await subject.onRefreshTokenError(error: IdentityTokenRefreshRequestError.invalidGrant)

        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.events, [.didLogout(userId: nil, userInitiated: false)])
    }

    /// `onRefreshTokenError(error:)` doesn't perform log out when error is not `.invalidGrant`.
    @MainActor
    func test_onRefreshTokenError_notInvalidGrant() async throws {
        coordinator.isLoadingOverlayShowing = true

        try await subject.onRefreshTokenError(error: BitwardenTestError.example)

        XCTAssertFalse(authRepository.logoutCalled)
        XCTAssertTrue(coordinator.isLoadingOverlayShowing)
        XCTAssertTrue(coordinator.events.isEmpty)
    }
}
