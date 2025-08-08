import AuthenticationServices
import BitwardenResources
import BitwardenSdk
import Combine
import Foundation
import UIKit

// MARK: - AppLinksError

/// The errors thrown from a `AppProcessor`.
///
enum AppProcessorError: Error {
    /// The received URL from AppLinks is malformed.
    case appLinksInvalidURL

    /// The received URL from AppLinks does not have the correct parameters.
    case appLinksInvalidParametersForPath

    /// The received URL from AppLinks does not have a valid path.
    case appLinksInvalidPath

    /// The operation to execute is invalid.
    case invalidOperation
}

/// The `AppProcessor` processes actions received at the application level and contains the logic
/// to control the top-level flow through the app.
///
@MainActor
public class AppProcessor {
    // MARK: Properties

    /// A delegate used to communicate with the app extension.
    private(set) weak var appExtensionDelegate: AppExtensionDelegate?

    /// The mediator to handle `AppIntent` actions.
    private let appIntentMediator: AppIntentMediator?

    /// The root module to use to create sub-coordinators.
    let appModule: AppModule

    /// The background task ID for the background process to send events on backgrounding.
    var backgroundTaskId: UIBackgroundTaskIdentifier?

    /// The root coordinator of the app.
    var coordinator: AnyCoordinator<AppRoute, AppEvent>?

    /// A timer to send any accumulated events every five minutes.
    private(set) var sendEventTimer: Timer?

    /// The services used by the app.
    let services: ServiceContainer

    // MARK: Initialization

    /// Initializes an `AppProcessor`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - appIntentMediator: The mediator to handle `AppIntent` actions.
    ///   - appModule: The root module to use to create sub-coordinators.
    ///   - debugDidEnterBackground: A closure that is called in debug builds for testing after the
    ///     processor finishes its work when the app enters the background.
    ///   - debugWillEnterForeground: A closure that is called in debug builds for testing after the
    ///     processor finishes its work when the app enters the foreground.
    ///   - services: The services used by the app.
    ///
    public init(
        appExtensionDelegate: AppExtensionDelegate? = nil,
        appIntentMediator: AppIntentMediator? = nil,
        appModule: AppModule,
        debugDidEnterBackground: (() -> Void)? = nil,
        debugWillEnterForeground: (() -> Void)? = nil,
        services: ServiceContainer
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.appIntentMediator = appIntentMediator
        self.appModule = appModule
        self.services = services

        self.services.notificationService.setDelegate(self)
        self.services.pendingAppIntentActionMediator.setDelegate(self)
        self.services.syncService.delegate = self

        Task {
            await services.apiService.setAccountTokenProviderDelegate(delegate: self)
        }

        startEventTimer()

        UI.initialLanguageCode = services.appSettingsStore.appLocale ?? Bundle.main.preferredLocalizations.first
        UI.applyDefaultAppearances()

        Task {
            for await _ in services.notificationCenterService.willEnterForegroundPublisher() {
                startEventTimer()
                await checkIfExtensionSwitchedAccounts()
                await services.authRepository.checkSessionTimeouts { [weak self] activeUserId in
                    // Allow the AuthCoordinator to handle the timeout for the active user
                    // so any necessary routing can occur.
                    await self?.coordinator?.handleEvent(.didTimeout(userId: activeUserId))
                }
                await handleNeverTimeOutAccountBecameActive()
                await completeAutofillAccountSetupIfEnabled()
                #if DEBUG
                debugWillEnterForeground?()
                #endif
            }
        }

        Task {
            for await _ in services.notificationCenterService.didEnterBackgroundPublisher() {
                stopEventTimer()
                do {
                    let userId = try await self.services.stateService.getActiveAccountId()
                    try await services.vaultTimeoutService.setLastActiveTime(userId: userId)
                } catch StateServiceError.noActiveAccount {
                    // No-op: nothing to do if there's no active account.
                } catch {
                    services.errorReporter.log(error: error)
                }
                #if DEBUG
                debugDidEnterBackground?()
                #endif
            }
        }

        // PM-19400: We need to listen to the changes on pending app intent actions
        // so they get executed and update the navigation/UI accordingly.
        Task {
            for await _ in await services.stateService.pendingAppIntentActionsPublisher().values {
                await services.pendingAppIntentActionMediator.executePendingAppIntentActions()
            }
        }
    }

    // MARK: Methods

    /// Handles receiving a deep link URL and routing to the appropriate place in the app.
    ///
    /// - Parameter url: The deep link URL to handle.
    ///
    public func openUrl(_ url: URL) async {
        var route = await getBitwardenUrlRoute(url: url)
        if route == nil {
            route = await getOtpAuthUrlRoute(url: url)
        }
        guard let route else { return }
        await checkIfLockedAndPerformNavigation(route: route)
    }

    /// Starts the application flow by navigating the user to the first flow.
    ///
    /// - Parameters:
    ///   - appContext: The context that the app is running within.
    ///   - initialRoute: The initial route to navigate to. If `nil` this, will navigate to the
    ///     unlock or landing auth route based on if there's an active account. Defaults to `nil`.
    ///   - navigator: The object that will be used to navigate between routes.
    ///   - splashWindow: The splash window to use to set the app's theme.
    ///   - window: The window to use to set the app's theme.
    ///
    public func start(
        appContext: AppContext,
        initialRoute: AppRoute? = nil,
        navigator: RootNavigator,
        splashWindow: UIWindow? = nil,
        window: UIWindow?
    ) async {
        let coordinator = appModule.makeAppCoordinator(appContext: appContext, navigator: navigator)
        coordinator.start()
        self.coordinator = coordinator

        Task {
            for await appTheme in await services.stateService.appThemePublisher().values {
                navigator.appTheme = appTheme
                splashWindow?.overrideUserInterfaceStyle = appTheme.userInterfaceStyle
                window?.overrideUserInterfaceStyle = appTheme.userInterfaceStyle
            }
        }

        await services.flightRecorder.log(
            "App launched, context: \(appContext), version: \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))"
        )

        await services.migrationService.performMigrations()
        await services.environmentService.loadURLsForActiveAccount()
        _ = await services.configService.getConfig()
        await completeAutofillAccountSetupIfEnabled()

        if let initialRoute {
            coordinator.navigate(to: initialRoute)
        } else {
            await coordinator.handleEvent(.didStart)
        }
    }

    /// Handle incoming URL from iOS AppLinks and redirect it to the correct navigation within the App
    ///
    /// - Parameter incomingURL: The URL handled from AppLinks.
    ///
    public func handleAppLinks(incomingURL: URL) {
        guard let sanitizedUrl = URL(
            string: incomingURL.absoluteString.replacingOccurrences(of: "/redirect-connector.html#", with: "/")
        ),
            let components = URLComponents(url: sanitizedUrl, resolvingAgainstBaseURL: true) else {
            return
        }

        // Check for specific URL components that you need.
        guard let params = components.queryItems,
              components.host != nil else {
            services.errorReporter.log(error: AppProcessorError.appLinksInvalidURL)
            return
        }

        guard components.path == "/finish-signup" else {
            services.errorReporter.log(error: AppProcessorError.appLinksInvalidPath)
            return
        }
        guard let email = params.first(where: { $0.name == "email" })?.value,
              let verificationToken = params.first(where: { $0.name == "token" })?.value,
              let fromEmail = params.first(where: { $0.name == "fromEmail" })?.value
        else {
            services.errorReporter.log(error: AppProcessorError.appLinksInvalidParametersForPath)
            return
        }

        coordinator?.navigate(to: AppRoute.auth(
            AuthRoute.completeRegistrationFromAppLink(
                emailVerificationToken: verificationToken,
                userEmail: email,
                fromEmail: Bool(fromEmail) ?? true
            )))
    }

    /// Handles importing credentials using Credential Exchange Protocol.
    /// - Parameter credentialImportToken: The credentials import token to user with the `ASCredentialImportManager`.
    @available(iOSApplicationExtension 26.0, *)
    public func handleImportCredentials(credentialImportToken: UUID) async {
        let route = AppRoute.tab(.vault(.importCXF(
            .importCredentials(credentialImportToken: credentialImportToken)
        )))
        await checkIfLockedAndPerformNavigation(route: route)
    }

    // MARK: Autofill Methods

    /// Returns a `ASPasswordCredential` that matches the user-requested credential which can be
    /// used for autofill.
    ///
    /// - Parameters:
    ///   - id: The identifier of the user-requested credential to return.
    ///   - repromptPasswordValidated: `true` if master password reprompt was required for the
    ///     cipher and the user's master password was validated.
    /// - Returns: A `ASPasswordCredential` that matches the user-requested credential which can be
    ///     used for autofill.
    ///
    public func provideCredential(
        for id: String,
        repromptPasswordValidated: Bool = false
    ) async throws -> ASPasswordCredential {
        try await services.autofillCredentialService.provideCredential(
            for: id,
            autofillCredentialServiceDelegate: self,
            repromptPasswordValidated: repromptPasswordValidated
        )
    }

    /// Provides an OTP credential for the identity
    /// - Parameters:
    ///   - id: The identifier of the user-requested credential to return
    ///   - repromptPasswordValidated: true` if master password reprompt was required for the
    ///     cipher and the user's master password was validated.
    /// - Returns: An `ASOneTimeCodeCredential` that matches the user-requested credential which can be
    ///     used for autofill..
    @available(iOSApplicationExtension 18.0, *)
    public func provideOTPCredential(
        for id: String,
        repromptPasswordValidated: Bool = false
    ) async throws -> ASOneTimeCodeCredential {
        try await services.autofillCredentialService.provideOTPCredential(
            for: id,
            autofillCredentialServiceDelegate: self,
            repromptPasswordValidated: repromptPasswordValidated
        )
    }

    /// Reprompts the user for their master password if the cipher for the user-requested credential
    /// requires reprompt. Once reprompt has been completed (or when it's not required), the
    /// `completion` closure is called notifying the caller if the master password was validated
    /// successfully for reprompt.
    ///
    /// - Parameters:
    ///   - id: The identifier of the user-requested credential to return.
    ///   - completion: A closure that is called containing a bool that identifies if the user's
    ///     master password was validated successfully. This will be `false` if reprompt wasn't
    ///     required or if it is required and the master password was incorrect.
    ///
    public func repromptForCredentialIfNecessary(
        for id: String,
        completion: @escaping (Bool) async -> Void
    ) async throws {
        guard try await services.vaultRepository.repromptRequiredForCipher(id: id) else {
            await completion(false)
            return
        }

        let alert = Alert.masterPasswordPrompt { password in
            do {
                let isValid = try await self.services.authRepository.validatePassword(password)
                guard isValid else {
                    self.coordinator?.showAlert(.defaultAlert(title: Localizations.invalidMasterPassword)) {
                        Task {
                            await completion(false)
                        }
                    }
                    return
                }
                await completion(true)
            } catch {
                self.services.errorReporter.log(error: error)
                await completion(false)
            }
        }
        coordinator?.showAlert(alert)
    }

    /// Show the debug menu.
    public func showDebugMenu() {
        coordinator?.navigate(to: .debugMenu)
    }

    // MARK: Notification Methods

    /// Called when the app has registered for push notifications.
    ///
    /// - Parameter tokenData: The device token for push notifications.
    ///
    public func didRegister(withToken tokenData: Data) {
        Task {
            await services.notificationService.didRegister(withToken: tokenData)
        }
    }

    /// Called when the app failed to register for push notifications.
    ///
    /// - Parameter error: The error received.
    ///
    public func failedToRegister(_ error: Error) {
        services.errorReporter.log(error: error)
    }

    /// Called when the app has received data from a push notification.
    ///
    /// - Parameters:
    ///   - message: The content of the push notification.
    ///   - notificationDismissed: `true` if a notification banner has been dismissed.
    ///   - notificationTapped: `true` if a notification banner has been tapped.
    ///
    public func messageReceived(
        _ message: [AnyHashable: Any],
        notificationDismissed: Bool? = nil,
        notificationTapped: Bool? = nil
    ) async {
        await services.notificationService.messageReceived(
            message,
            notificationDismissed: notificationDismissed,
            notificationTapped: notificationTapped
        )
    }
}

extension AppProcessor {
    // MARK: Private Methods

    /// Whether there are pending `AppIntent` lock actions.
    private func hasLockPendingAppIntentAction() async -> Bool {
        guard let actions = await services.stateService.getPendingAppIntentActions(),
              !actions.isEmpty else {
            return false
        }

        return actions.contains(where: { $0 == .lockAll })
    }

    /// Handles unlocking the vault for a manually locked account that uses never lock
    /// and was previously unlocked in an extension.
    ///
    private func handleNeverTimeOutAccountBecameActive() async {
        guard
            appExtensionDelegate?.isInAppExtension != true,
            await (try? services.authRepository.isLocked()) == true,
            await (try? services.authRepository.sessionTimeoutValue()) == .never,
            await (try? services.stateService.getManuallyLockedAccount(userId: nil)) == false,
            await !hasLockPendingAppIntentAction(),
            let account = try? await services.stateService.getActiveAccount()
        else { return }

        await coordinator?.handleEvent(
            .accountBecameActive(
                account,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// Checks if the active account was switched while in the extension. If this occurs, the app
    /// needs to also switch to the updated active account.
    ///
    private func checkIfExtensionSwitchedAccounts() async {
        guard appExtensionDelegate?.isInAppExtension != true else { return }
        do {
            guard try await services.stateService.didAccountSwitchInExtension() == true else { return }
            let userId = try await services.stateService.getActiveAccountId()
            await coordinator?.handleEvent(.switchAccounts(userId: userId, isAutomatic: false))
        } catch StateServiceError.noActiveAccount {
            await coordinator?.handleEvent(.didStart)
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Checks if the vault is locked and performs the navigation to the `AppRoute`
    /// or sets it as the auth completion route.
    /// - Parameter route: The `AppRoute` to go to.
    private func checkIfLockedAndPerformNavigation(route: AppRoute) async {
        if let userId = try? await services.stateService.getActiveAccountId(),
           !services.vaultTimeoutService.isLocked(userId: userId),
           await (try? services.vaultTimeoutService.hasPassedSessionTimeout(userId: userId)) == false {
            coordinator?.navigate(to: route)
        } else {
            await coordinator?.handleEvent(.setAuthCompletionRoute(route))
        }
    }

    /// If the native create account feature flag and the autofill extension are enabled, this marks
    /// any user's autofill account setup completed. This should be called on app startup.
    ///
    private func completeAutofillAccountSetupIfEnabled() async {
        // Don't mark the user's progress as complete in the extension, otherwise the app may not
        // see that the user's progress needs to be updated to publish new values to subscribers.
        guard appExtensionDelegate?.isInAppExtension != true,
              await services.autofillCredentialService.isAutofillCredentialsEnabled()
        else { return }
        do {
            let accounts = try await services.stateService.getAccounts()
            for account in accounts {
                let userId = account.profile.userId
                guard let progress = await services.stateService.getAccountSetupAutofill(userId: userId),
                      progress != .complete
                else { continue }
                try await services.stateService.setAccountSetupAutofill(.complete, userId: userId)
            }
        } catch StateServiceError.noAccounts {
            // No-op: nothing to do if there's no accounts.
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Attempt to create an `AppRoute` from an "bitwarden://" url.
    ///
    /// - Parameter url: The Bitwarden URL received by the app.
    /// - Returns: an `AppRoute` if one was successfully built from the URL passed in, `nil` if not.
    ///
    private func getBitwardenUrlRoute(url: URL) async -> AppRoute? {
        guard let scheme = url.scheme, scheme.isBitwardenAppScheme else { return nil }

        switch url.absoluteString {
        case BitwardenDeepLinkConstants.accountSecurity:
            return AppRoute.tab(.settings(.accountSecurity))
        case BitwardenDeepLinkConstants.authenticatorNewItem:
            guard let item = await services.authenticatorSyncService?.getTemporaryTotpItem(),
                  let totpKey = item.totpKey else {
                coordinator?.showAlert(.defaultAlert(title: Localizations.somethingWentWrong,
                                                     message: Localizations.unableToMoveTheSelectedItemPleaseTryAgain))
                return nil
            }

            let totpKeyModel = TOTPKeyModel(authenticatorKey: totpKey)
            return AppRoute.tab(.vault(.vaultItemSelection(totpKeyModel)))
        default:
            return nil
        }
    }

    /// Attempt to create an `AppRoute` from an "otpauth://" url.
    ///
    /// - Parameter url: The OTPAuth URL received by the app.
    /// - Returns: an `AppRoute` if one was successfully built from the URL passed in, `nil` if not.
    ///
    private func getOtpAuthUrlRoute(url: URL) async -> AppRoute? {
        guard let scheme = url.scheme, scheme.isOtpAuthScheme else { return nil }

        let totpKeyModel = TOTPKeyModel(authenticatorKey: url.absoluteString)
        guard case .otpAuthUri = totpKeyModel.totpKey else {
            coordinator?.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            return nil
        }

        return AppRoute.tab(.vault(.vaultItemSelection(totpKeyModel)))
    }

    /// Logs out the user automatically, if `nil` is passed as `userId` then it will act on the current user.
    /// - Parameter userId: The ID of the user to logout, current if `nil`.
    private func logOutAutomatically(userId: String? = nil) async {
        coordinator?.hideLoadingOverlay()
        do {
            try await services.authRepository.logout(userId: userId, userInitiated: false)
        } catch {
            services.errorReporter.log(error: error)
        }
        await coordinator?.handleEvent(.didLogout(userId: userId, userInitiated: false))
    }

    /// Starts timer to send organization events regularly
    private func startEventTimer() {
        sendEventTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { _ in
            Task { [weak self] in
                await self?.uploadEvents()
            }
        }
        sendEventTimer?.tolerance = 10
    }

    /// Stops the timer for organization events
    private func stopEventTimer() {
        sendEventTimer?.fire()
        sendEventTimer?.invalidate()
    }

    /// Sends organization events to the server. Also sets up that regular upload
    /// as a Background Task so that it won't be canceled when the app is going
    /// to the background. Per https://forums.developer.apple.com/forums/thread/85066
    /// calling this for every upload (not just ones where we're backgrounding)
    /// is fine.
    private func uploadEvents() async {
        if let taskId = backgroundTaskId {
            services.application?.endBackgroundTask(taskId)
            backgroundTaskId = nil
        }
        backgroundTaskId = services.application?.startBackgroundTask(
            withName: "SendEventBackgroundTask",
            expirationHandler: { [weak self] in
                if let backgroundTaskId = self?.backgroundTaskId {
                    self?.services.application?.endBackgroundTask(backgroundTaskId)
                    self?.backgroundTaskId = nil
                }
            }
        )
        await services.eventService.upload()
        if let taskId = backgroundTaskId {
            services.application?.endBackgroundTask(taskId)
            backgroundTaskId = nil
        }
    }
}

// MARK: - NotificationServiceDelegate

extension AppProcessor: NotificationServiceDelegate {
    /// Users are logged out, route to landing page.
    ///
    func routeToLanding() async {
        coordinator?.navigate(to: .auth(.landing))
    }

    /// Show the login request.
    ///
    /// - Parameter loginRequest: The login request.
    ///
    func showLoginRequest(_ loginRequest: LoginRequest) {
        coordinator?.navigate(to: .loginRequest(loginRequest))
    }

    /// Switch the active account in order to show the login request, prompting the user if necessary.
    ///
    /// - Parameters:
    ///   - account: The account associated with the login request.
    ///   - showAlert: Whether to show the alert or simply switch the account.
    ///
    func switchAccountsForLoginRequest(to account: Account, showAlert: Bool) async {
        if showAlert {
            coordinator?.showAlert(.confirmation(
                title: Localizations.logInRequested,
                message: Localizations.loginAttemptFromXDoYouWantToSwitchToThisAccount(account.profile.email)
            ) {
                await self.switchAccountsForLoginRequest(to: account.profile.userId)
            })
        } else {
            await switchAccountsForLoginRequest(to: account.profile.userId)
        }
    }

    /// Switch to the specified account so they can see the login request.
    ///
    /// - Parameter userId: The user ID of the account to switch to.
    ///
    private func switchAccountsForLoginRequest(to userId: String) async {
        // Switch to the account, the login request will be shown when their vault loads (either
        // immediately or after vault unlock).
        await coordinator?.handleEvent(.switchAccounts(userId: userId, isAutomatic: false))
    }
}

// MARK: - SyncServiceDelegate

extension AppProcessor: SyncServiceDelegate {
    func onFetchSyncSucceeded(userId: String) async {
        do {
            let hasPerformedSyncAfterLogin = try await services.stateService.getHasPerformedSyncAfterLogin(
                userId: userId
            )
            // Check so the next gets executed only once after login.
            guard !hasPerformedSyncAfterLogin else {
                return
            }
            try await services.stateService.setHasPerformedSyncAfterLogin(true, userId: userId)

            if await services.policyService.policyAppliesToUser(.removeUnlockWithPin) {
                try await services.stateService.clearPins()
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    func removeMasterPassword(organizationName: String, organizationId: String, keyConnectorUrl: String) {
        // Don't show the remove master password screen if running in an app extension.
        guard appExtensionDelegate?.isInAppExtension != true else { return }

        coordinator?.hideLoadingOverlay()
        coordinator?.navigate(to: .auth(.removeMasterPassword(
            organizationName: organizationName,
            organizationId: organizationId,
            keyConnectorUrl: keyConnectorUrl
        )))
    }

    func securityStampChanged(userId: String) async {
        // Log the user out if their security stamp changes.
        await logOutAutomatically(userId: userId)
    }

    func setMasterPassword(orgIdentifier: String) async {
        DispatchQueue.main.async { [self] in
            coordinator?.navigate(to: .auth(.setMasterPassword(organizationIdentifier: orgIdentifier)))
        }
    }
}

// MARK: - Fido2 credentials

public extension AppProcessor {
    /// Provides a Fido2 credential for a passkey request
    /// - Parameters:
    ///   - passkeyRequest: Request to get the credential.
    /// - Returns: The passkey credential for assertion.
    @available(iOS 17.0, *)
    func provideFido2Credential(
        for passkeyRequest: ASPasskeyCredentialRequest
    ) async throws -> ASPasskeyAssertionCredential {
        try await services.autofillCredentialService.provideFido2Credential(
            for: passkeyRequest,
            autofillCredentialServiceDelegate: self,
            fido2UserInterfaceHelperDelegate: self
        )
    }
}

// MARK: - AccountTokenProviderDelegate

extension AppProcessor: AccountTokenProviderDelegate {
    func onRefreshTokenError(error: any Error) async throws {
        if case IdentityTokenRefreshRequestError.invalidGrant = error {
            await logOutAutomatically()
        }
    }
}

// MARK: - AutofillCredentialServiceDelegate

extension AppProcessor: AutofillCredentialServiceDelegate {
    func unlockVaultWithNeverlockKey() async throws {
        try await services.authRepository.unlockVaultWithNeverlockKey()
    }
}

// MARK: - Fido2UserVerificationMediatorDelegate

extension AppProcessor: Fido2UserInterfaceHelperDelegate {
    // MARK: Properties

    var isAutofillingFromList: Bool {
        guard let autofillAppExtensionDelegate = appExtensionDelegate as? AutofillAppExtensionDelegate,
              autofillAppExtensionDelegate.isAutofillingFido2CredentialFromList else {
            return false
        }
        return true
    }

    // MARK: Methods

    func informExcludedCredentialFound(cipherView: BitwardenSdk.CipherView) async {
        // No-op
    }

    func onNeedsUserInteraction() async throws {
        guard let autofillAppExtensionDelegate = appExtensionDelegate as? AutofillAppExtensionDelegate else {
            return
        }

        if !autofillAppExtensionDelegate.flowWithUserInteraction {
            autofillAppExtensionDelegate.setUserInteractionRequired()
            throw Fido2Error.userInteractionRequired
        }

        // WORKAROUND: We need to wait until the view controller appears in order to perform any
        // action that needs user interaction or it might not show the prompt to the user.
        // E.g. without this there are certain devices that don't show the FaceID prompt
        // and the user only sees the screen dimming a bit and failing the flow.
        for await didAppear in autofillAppExtensionDelegate.getDidAppearPublisher() {
            guard didAppear else { continue }
            return
        }
    }

    func showAlert(_ alert: Alert) {
        coordinator?.showAlert(alert)
    }

    func showAlert(_ alert: Alert, onDismissed: (() -> Void)?) {
        coordinator?.showAlert(alert, onDismissed: onDismissed)
    }
}

// MARK: - PendingAppIntentActionMediatorDelegate

extension AppProcessor: PendingAppIntentActionMediatorDelegate {
    func onPendingAppIntentActionSuccess(
        _ pendingAppIntentAction: PendingAppIntentAction,
        data: Any?
    ) async {
        switch pendingAppIntentAction {
        case .lockAll:
            guard let account = data as? Account else {
                return
            }
            await coordinator?.handleEvent(
                .accountBecameActive(
                    account,
                    attemptAutomaticBiometricUnlock: true,
                    didSwitchAccountAutomatically: false
                )
            )
        case .logOutAll:
            await coordinator?.handleEvent(.didLogout(userId: nil, userInitiated: true))
        case .openGenerator:
            await checkIfLockedAndPerformNavigation(route: .tab(.generator(.generator())))
        }
    }
}

// swiftlint:disable:this file_length
