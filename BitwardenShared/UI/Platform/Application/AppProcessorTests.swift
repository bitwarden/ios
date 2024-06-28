import AuthenticationServices
import Foundation
import XCTest

@testable import BitwardenShared

class AppProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appModule: MockAppModule!
    var authRepository: MockAuthRepository!
    var autofillCredentialService: MockAutofillCredentialService!
    var clientService: MockClientService!
    var coordinator: MockCoordinator<AppRoute, AppEvent>!
    var errorReporter: MockErrorReporter!
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

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        router = MockRouter(routeForEvent: { _ in .landing })
        appModule = MockAppModule()
        authRepository = MockAuthRepository()
        autofillCredentialService = MockAutofillCredentialService()
        clientService = MockClientService()
        coordinator = MockCoordinator()
        appModule.authRouter = router
        appModule.appCoordinator = coordinator
        errorReporter = MockErrorReporter()
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
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                autofillCredentialService: autofillCredentialService,
                clientService: clientService,
                errorReporter: errorReporter,
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
        coordinator = nil
        errorReporter = nil
        migrationService = nil
        notificationCenterService = nil
        notificationService = nil
        stateService = nil
        subject = nil
        syncService = nil
        timeProvider = nil
        vaultRepository = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

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

    /// `didRegister(withToken:)` passes the token to the notification service.
    func test_didRegister() throws {
        let tokenData = try XCTUnwrap("tokensForFree".data(using: .utf8))

        let task = Task {
            subject.didRegister(withToken: tokenData)
        }

        waitFor(notificationService.registrationTokenData == tokenData)
        task.cancel()
    }

    /// `failedToRegister(_:)` records the error.
    func test_failedToRegister() {
        subject.failedToRegister(BitwardenTestError.example)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `init()` sets the `AppProcessor` as the delegate of any necessary services.
    func test_init_setDelegates() {
        XCTAssertIdentical(notificationService.delegate, subject)
        XCTAssertIdentical(syncService.delegate, subject)
    }

    /// `messageReceived(_:notificationDismissed:notificationTapped)` passes the data to the notification service.
    func test_messageReceived() async {
        let message: [AnyHashable: Any] = ["knock knock": "who's there?"]

        await subject.messageReceived(message)

        XCTAssertEqual(notificationService.messageReceivedMessage?.keys.first, "knock knock")
    }

    /// `openUrl(_:)` handles receiving an OTP deep link and setting an auth completion route on the
    /// coordinator to handle routing to the vault item selection screen when the vault is unlocked.
    func test_openUrl_otpKey_vaultLocked() async throws {
        let otpKey: String = .otpAuthUriKeyComplete

        try await subject.openUrl(XCTUnwrap(URL(string: otpKey)))

        let model = try XCTUnwrap(OTPAuthModel(otpAuthKey: otpKey))
        XCTAssertEqual(coordinator.events, [.setAuthCompletionRoute(.tab(.vault(.vaultItemSelection(model))))])
    }

    /// `openUrl(_:)` handles receiving an OTP deep link and routing to the vault item selection screen.
    func test_openUrl_otpKey_vaultUnlocked() async throws {
        let account = Account.fixture()
        let otpKey: String = .otpAuthUriKeyComplete
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false

        try await subject.openUrl(XCTUnwrap(URL(string: otpKey)))

        let model = try XCTUnwrap(OTPAuthModel(otpAuthKey: otpKey))
        XCTAssertEqual(coordinator.routes.last, .tab(.vault(.vaultItemSelection(model))))
    }

    /// `openUrl(_:)` handles receiving an OTP deep link if the URL isn't an OTP key.
    func test_openUrl_otpKey_invalid() async throws {
        try await subject.openUrl(XCTUnwrap(URL(string: "https://google.com")))

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

    /// `repromptForCredentialIfNecessary(for:)` reprompts the user for their master password if
    /// reprompt is enabled for the cipher.
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
    func test_routeToLanding() async {
        await subject.routeToLanding()
        XCTAssertEqual(coordinator.routes.last, .auth(.landing))
    }

    /// `securityStampChanged(userId:)` logs the user out and notifies the coordinator.
    func test_securityStampChanged() async {
        coordinator.isLoadingOverlayShowing = true

        await subject.securityStampChanged(userId: "1")

        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertEqual(authRepository.logoutUserId, "1")
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.events, [.didLogout(userId: "1", userInitiated: false)])
    }

    /// Upon a session timeout on app foreground, send the user to the `.didTimeout` route.
    func test_shouldSessionTimeout_navigateTo_didTimeout() throws {
        let rootNavigator = MockRootNavigator()
        let user = Account.fixture()
        let userId = user.profile.userId
        let user2 = Account.fixture()
        let user2Id = user2.profile.userId

        stateService.activeAccount = user
        stateService.accounts = [user, user2]

        let task = Task {
            await subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)
        }
        waitFor(coordinator.events == [.didStart])
        task.cancel()

        vaultTimeoutService.shouldSessionTimeout[userId] = true
        notificationCenterService.willEnterForegroundSubject.send()

        waitFor(vaultTimeoutService.shouldSessionTimeout[userId] == true)
        waitFor(coordinator.events.count > 1)
        waitFor(vaultTimeoutService.isLocked(userId: user2Id))

        XCTAssertEqual(
            coordinator.events,
            [
                .didStart,
                .didTimeout(userId: userId),
            ]
        )
    }

    /// `showLoginRequest(_:)` navigates to show the login request view.
    func test_showLoginRequest() {
        subject.showLoginRequest(.fixture())
        XCTAssertEqual(coordinator.routes.last, .loginRequest(.fixture()))
    }

    /// `start(navigator:)` builds the AppCoordinator and navigates to the initial route if provided.
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
    func test_start_authRoute() async {
        let rootNavigator = MockRootNavigator()

        await subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        waitFor(!coordinator.events.isEmpty)

        XCTAssertTrue(appModule.appCoordinator.isStarted)
        XCTAssertEqual(appModule.appCoordinator.events, [.didStart])
        XCTAssertEqual(migrationService.didPerformMigrations, true)
    }
}
