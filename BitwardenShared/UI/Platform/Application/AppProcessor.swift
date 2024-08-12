import AuthenticationServices
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
    ///   - appModule: The root module to use to create sub-coordinators.
    ///   - services: The services used by the app.
    ///
    public init(
        appExtensionDelegate: AppExtensionDelegate? = nil,
        appModule: AppModule,
        services: ServiceContainer
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.appModule = appModule
        self.services = services

        self.services.notificationService.setDelegate(self)
        self.services.syncService.delegate = self

        startEventTimer()

        UI.initialLanguageCode = services.appSettingsStore.appLocale ?? Locale.current.languageCode
        UI.applyDefaultAppearances()

        Task {
            for await _ in services.notificationCenterService.willEnterForegroundPublisher() {
                startEventTimer()
                await checkAccountsForTimeout()
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
            }
        }
    }

    // MARK: Methods

    /// Handles receiving a deep link URL and routing to the appropriate place in the app.
    ///
    /// - Parameter url: The deep link URL to handle.
    ///
    public func openUrl(_ url: URL) async {
        guard let otpAuthModel = OTPAuthModel(otpAuthKey: url.absoluteString) else {
            coordinator?.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            return
        }

        let vaultItemSelectionRoute = AppRoute.tab(.vault(.vaultItemSelection(otpAuthModel)))
        guard let userId = try? await services.stateService.getActiveAccountId(),
              !services.vaultTimeoutService.isLocked(userId: userId),
              await (try? services.vaultTimeoutService.hasPassedSessionTimeout(userId: userId)) == false
        else {
            await coordinator?.handleEvent(.setAuthCompletionRoute(vaultItemSelectionRoute))
            return
        }
        coordinator?.navigate(to: vaultItemSelectionRoute)
    }

    /// Starts the application flow by navigating the user to the first flow.
    ///
    /// - Parameters:
    ///   - appContext: The context that the app is running within.
    ///   - initialRoute: The initial route to navigate to. If `nil` this, will navigate to the
    ///     unlock or landing auth route based on if there's an active account. Defaults to `nil`.
    ///   - navigator: The object that will be used to navigate between routes.
    ///   - window: The window to use to set the app's theme.
    ///
    public func start(
        appContext: AppContext,
        initialRoute: AppRoute? = nil,
        navigator: RootNavigator,
        window: UIWindow?
    ) async {
        let coordinator = appModule.makeAppCoordinator(appContext: appContext, navigator: navigator)
        coordinator.start()
        self.coordinator = coordinator

        Task {
            for await appTheme in await services.stateService.appThemePublisher().values {
                navigator.appTheme = appTheme
                window?.overrideUserInterfaceStyle = appTheme.userInterfaceStyle
            }
        }

        await services.migrationService.performMigrations()
        await services.environmentService.loadURLsForActiveAccount()
        _ = await services.configService.getConfig()

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
        guard let sanatizedUrl = URL(string: incomingURL.absoluteString.replacingOccurrences(of: "/#/", with: "/")),
              let components = URLComponents(url: sanatizedUrl, resolvingAgainstBaseURL: true) else {
            return
        }

        // Check for specific URL components that you need.
        guard let params = components.queryItems,
              let host = components.host else {
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
                fromEmail: Bool(fromEmail) ?? true,
                region: host.contains(RegionType.europe.baseUrlDescription) ? .europe : .unitedStates
            )))
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

    // MARK: Private Methods

    /// Checks if any accounts have timed out.
    ///
    private func checkAccountsForTimeout() async {
        do {
            let accounts = try await services.stateService.getAccounts()
            let activeUserId = try await services.stateService.getActiveAccountId()
            for account in accounts {
                let userId = account.profile.userId
                let shouldTimeout = try await services.vaultTimeoutService.hasPassedSessionTimeout(userId: userId)
                if shouldTimeout {
                    if userId == activeUserId {
                        // Allow the AuthCoordinator to handle the timeout for the active user
                        // so any necessary routing can occur.
                        await coordinator?.handleEvent(.didTimeout(userId: activeUserId))
                    } else {
                        let timeoutAction = try? await services.authRepository.sessionTimeoutAction(userId: userId)
                        switch timeoutAction {
                        case .lock:
                            await services.vaultTimeoutService.lockVault(userId: userId)
                        case .logout, .none:
                            try await services.authRepository.logout(userId: userId)
                        }
                    }
                }
            }
        } catch StateServiceError.noAccounts, StateServiceError.noActiveAccount {
            // No-op: nothing to do if there's no accounts or an active account.
        } catch {
            services.errorReporter.log(error: error)
        }
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
        backgroundTaskId = services.application?.beginBackgroundTask(
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
    ///   - loginRequest: The login request to show.
    ///   - showAlert: Whether to show the alert or simply switch the account.
    ///
    func switchAccounts(to account: Account, for loginRequest: LoginRequest, showAlert: Bool) {
        DispatchQueue.main.async {
            if showAlert {
                self.coordinator?.showAlert(.confirmation(
                    title: Localizations.logInRequested,
                    message: Localizations.loginAttemptFromXDoYouWantToSwitchToThisAccount(account.profile.email)
                ) {
                    self.switchAccounts(to: account.profile.userId, for: loginRequest)
                })
            } else {
                self.switchAccounts(to: account.profile.userId, for: loginRequest)
            }
        }
    }

    /// Switch to the specified account and show the login request.
    ///
    /// - Parameters:
    ///   - userId: The userId of the account to switch to.
    ///   - loginRequest: The login request to show.
    ///
    private func switchAccounts(to userId: String, for loginRequest: LoginRequest) {
        (coordinator as? VaultCoordinatorDelegate)?.didTapAccount(userId: userId)
        coordinator?.navigate(to: .loginRequest(loginRequest))
    }
}

// MARK: - SyncServiceDelegate

extension AppProcessor: SyncServiceDelegate {
    func securityStampChanged(userId: String) async {
        // Log the user out if their security stamp changes.
        coordinator?.hideLoadingOverlay()
        try? await services.authRepository.logout(userId: userId)
        await coordinator?.handleEvent(.didLogout(userId: userId, userInitiated: false))
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

// MARK: - AutofillCredentialServiceDelegate

extension AppProcessor: AutofillCredentialServiceDelegate {
    func unlockVaultWithNeverlockKey() async throws {
        try await services.authRepository.unlockVaultWithNeverlockKey()
    }
}

// MARK: - Fido2UserVerificationMediatorDelegate

extension AppProcessor: Fido2UserInterfaceHelperDelegate {
    var isAutofillingFromList: Bool {
        guard let fido2AppExtensionDelegate = appExtensionDelegate as? Fido2AppExtensionDelegate,
              fido2AppExtensionDelegate.isAutofillingFido2CredentialFromList else {
            return false
        }
        return true
    }

    func onNeedsUserInteraction() async throws {
        guard let fido2AppExtensionDelegate = appExtensionDelegate as? Fido2AppExtensionDelegate else {
            return
        }

        if !fido2AppExtensionDelegate.flowWithUserInteraction {
            fido2AppExtensionDelegate.setUserInteractionRequired()
            throw Fido2Error.userInteractionRequired
        }

        // WORKAROUND: We need to wait until the view controller appears in order to perform any
        // action that needs user interaction or it might not show the prompt to the user.
        // E.g. without this there are certain devices that don't show the FaceID prompt
        // and the user only sees the screen dimming a bit and failing the flow.
        for await didAppear in fido2AppExtensionDelegate.getDidAppearPublisher() {
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

// swiftlint:disable:this file_length
