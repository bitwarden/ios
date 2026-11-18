import BitwardenKit
import Combine
import Foundation
import UIKit

// MARK: - AutofillPromptService

/// A service that tracks whether autofill is turned on and whether the autofill action card should
/// be shown to help the user turn it on.
///
protocol AutofillPromptService { // sourcery: AutoMockable
    /// A publisher for whether autofill is turned on. Emits `nil` until the autofill state has
    /// been checked for the first time.
    ///
    /// - Returns: A publisher for whether autofill is turned on.
    ///
    func autofillEnabledPublisher() -> AnyPublisher<Bool?, Never>

    /// Hides the vault's autofill action card until the next cold launch of the app.
    ///
    func dismissVaultActionCardForSession()

    /// Permanently hides the vault's autofill action card for all accounts on the device.
    ///
    func optOutOfVaultActionCard() async

    /// Checks whether autofill is turned on and publishes the result. If autofill was just turned
    /// on, the credential identity store is repopulated.
    ///
    func refreshAutofillStatus() async

    /// Requests that autofill be turned on, using the API available on the current OS version.
    ///
    /// - Returns: The URL of the app's page in the Settings app if the caller should open it
    ///   because the OS doesn't support a more direct option, otherwise `nil`.
    ///
    func turnOnAutofill() async -> URL?

    /// A publisher for whether the vault's autofill action card should be shown. The card is
    /// shown when autofill is off, the user hasn't opted out, and the card hasn't been dismissed
    /// during this session.
    ///
    /// - Returns: A publisher for whether the vault's autofill action card should be shown.
    ///
    func vaultActionCardVisibilityPublisher() async -> AnyPublisher<Bool, Never>
}

// MARK: - DefaultAutofillPromptService

/// The default implementation of `AutofillPromptService`.
///
class DefaultAutofillPromptService: AutofillPromptService {
    // MARK: Static Properties

    /// The URL of the app's page in the Settings app.
    private static let appSettingsURL = URL(string: UIApplication.openSettingsURLString)

    // MARK: Properties

    /// Provides the active account's ID.
    private let activeAccountStateProvider: ActiveAccountStateProvider

    /// The helper used to know the app context.
    private let appContextHelper: AppContextHelper

    /// The mediator used to make `ASSettingsHelper` calls, which enforces the wait time between
    /// requests to turn on the credential provider extension.
    private let asSettingsMediator: ASSettingsMediator

    /// The service that manages the credentials exposed to the system for autofill.
    private let autofillCredentialService: AutofillCredentialService

    /// The service used to get and set state around autofill.
    private let autofillStateService: AutofillStateService

    /// The number of seconds to wait after autofill is turned on before repopulating the
    /// credential identity store.
    private let credentialStoreUpdateDelay: TimeInterval

    /// The service used to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The subject publishing whether autofill is turned on, or `nil` if it hasn't been checked.
    private let isAutofillEnabledSubject = CurrentValueSubject<Bool?, Never>(nil)

    /// The subject publishing whether the vault action card was dismissed during this session.
    private let isDismissedForSessionSubject = CurrentValueSubject<Bool, Never>(false)

    /// The subject publishing whether the user opted out of the vault action card, or `nil` if it
    /// hasn't been loaded.
    private let isOptedOutSubject = CurrentValueSubject<Bool?, Never>(nil)

    /// The service used to determine whether the vault is locked.
    private let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultAutofillPromptService`.
    ///
    /// - Parameters:
    ///   - activeAccountStateProvider: Provides the active account's ID.
    ///   - appContextHelper: The helper used to know the app context.
    ///   - asSettingsMediator: The mediator used to make `ASSettingsHelper` calls, which enforces
    ///     the wait time between requests to turn on the credential provider extension.
    ///   - autofillCredentialService: The service that manages the credentials exposed to the
    ///     system for autofill.
    ///   - autofillStateService: The service used to get and set state around autofill.
    ///   - errorReporter: The service used to report non-fatal errors.
    ///   - vaultTimeoutService: The service used to determine whether the vault is locked.
    ///   - credentialStoreUpdateDelay: The number of seconds to wait after autofill is turned on
    ///     before repopulating the credential identity store.
    ///
    init(
        activeAccountStateProvider: ActiveAccountStateProvider,
        appContextHelper: AppContextHelper,
        asSettingsMediator: ASSettingsMediator,
        autofillCredentialService: AutofillCredentialService,
        autofillStateService: AutofillStateService,
        errorReporter: ErrorReporter,
        vaultTimeoutService: VaultTimeoutService,
        credentialStoreUpdateDelay: TimeInterval = Constants.autofillCredentialStoreUpdateDelay,
    ) {
        self.activeAccountStateProvider = activeAccountStateProvider
        self.appContextHelper = appContextHelper
        self.asSettingsMediator = asSettingsMediator
        self.autofillCredentialService = autofillCredentialService
        self.autofillStateService = autofillStateService
        self.credentialStoreUpdateDelay = credentialStoreUpdateDelay
        self.errorReporter = errorReporter
        self.vaultTimeoutService = vaultTimeoutService
    }

    // MARK: Methods

    func autofillEnabledPublisher() -> AnyPublisher<Bool?, Never> {
        isAutofillEnabledSubject.removeDuplicates().eraseToAnyPublisher()
    }

    func dismissVaultActionCardForSession() {
        isDismissedForSessionSubject.send(true)
    }

    func optOutOfVaultActionCard() async {
        isOptedOutSubject.send(true)
        await autofillStateService.setAutofillActionCardOptedOut(true)
    }

    func refreshAutofillStatus() async {
        guard appContextHelper.appContext == .mainApp else { return }

        let wasEnabled = isAutofillEnabledSubject.value
        let isEnabled = await autofillCredentialService.isAutofillCredentialsEnabled()
        isAutofillEnabledSubject.send(isEnabled)

        if wasEnabled == false, isEnabled {
            await updateCredentialsInStoreIfUnlocked()
        }
    }

    func turnOnAutofill() async -> URL? {
        if #available(iOS 18.0, *) {
            do {
                // The prompt's result isn't used; the live state decides what's shown.
                _ = try await asSettingsMediator.requestToTurnOnCredentialProviderExtension()
            } catch ASSettingsMediatorError.cantRequest {
                // The system prompt can't be shown again yet, so open the AutoFill settings instead.
                return await openCredentialProviderAppSettings()
            } catch {
                errorReporter.log(error: error)
                return await openCredentialProviderAppSettings()
            }

            await refreshAutofillStatus()
            return nil
        } else if #available(iOS 17.0, *) {
            return await openCredentialProviderAppSettings()
        } else {
            return Self.appSettingsURL
        }
    }

    func vaultActionCardVisibilityPublisher() async -> AnyPublisher<Bool, Never> {
        if isOptedOutSubject.value == nil {
            await isOptedOutSubject.send(autofillStateService.getAutofillActionCardOptedOut())
        }

        return isAutofillEnabledSubject
            .combineLatest(isDismissedForSessionSubject, isOptedOutSubject)
            .map { isEnabled, isDismissed, isOptedOut in
                isEnabled == false && !isDismissed && isOptedOut == false
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // MARK: Private

    /// Opens the AutoFill provider settings in the Settings app.
    ///
    /// - Returns: The URL of the app's page in the Settings app if the AutoFill provider settings
    ///   couldn't be opened, otherwise `nil`.
    ///
    @available(iOS 17.0, *)
    private func openCredentialProviderAppSettings() async -> URL? {
        do {
            try await asSettingsMediator.openCredentialProviderAppSettings()
            return nil
        } catch {
            errorReporter.log(error: error)
            return Self.appSettingsURL
        }
    }

    /// Repopulates the credential identity store, after a short delay, if the active account's
    /// vault is unlocked. If it's locked, the store is populated when the vault is unlocked.
    ///
    private func updateCredentialsInStoreIfUnlocked() async {
        do {
            let userId = try await activeAccountStateProvider.getActiveAccountId()
            guard await !vaultTimeoutService.isLocked(userId: userId) else { return }
            // The identity store rejects writes made right after the credential provider is turned
            // on, so wait briefly before repopulating it. This runs in its own task so callers,
            // like the app's foreground handling, aren't held up by the delay.
            Task { [autofillCredentialService, credentialStoreUpdateDelay] in
                do {
                    try await Task.sleep(nanoseconds: UInt64(credentialStoreUpdateDelay * 1_000_000_000))
                } catch {
                    // The task was cancelled, so skip repopulating the store.
                    return
                }
                await autofillCredentialService.updateCredentialsInStore()
            }
        } catch StateServiceError.noActiveAccount {
            // No-op: nothing to populate without an active account.
        } catch {
            errorReporter.log(error: error)
        }
    }
}
