import BitwardenKit
import BitwardenResources
@preconcurrency import BitwardenSdk
import Foundation

/// A helper class to handle when a cipher is selected for autofill.
///
@MainActor
class AutofillHelper {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasAutofillAssistService
        & HasErrorReporter
        & HasEventService
        & HasPasteboardService
        & HasStateService
        & HasVaultRepository

    // MARK: Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<VaultRoute, AuthAction>

    /// The services used by this helper.
    private let services: Services

    // MARK: Initialization

    /// Initialize an `AutofillHelper`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
        services: Services,
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.coordinator = coordinator
        self.services = services
    }

    // MARK: Methods

    /// Handles autofill for a selected cipher.
    ///
    /// - Parameters:
    ///   - cipherView: The `CipherListView` to use for autofill.
    ///   - showToast: A closure that when called will display a toast to the user.
    ///
    func handleCipherForAutofill(cipherListView: CipherListView, showToast: @escaping (String) -> Void) async {
        do {
            if cipherListView.reprompt == .password, try await services.authRepository.hasMasterPassword() {
                presentMasterPasswordRepromptAlert {
                    await self.handleCipherForAutofillAfterRepromptIfRequired(
                        cipherListView: cipherListView,
                        showToast: showToast,
                    )
                }
            } else {
                await handleCipherForAutofillAfterRepromptIfRequired(
                    cipherListView: cipherListView,
                    showToast: showToast,
                )
            }
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    // MARK: Private

    /// Copies the cipher's TOTP code to the clipboard if needed.
    /// - Parameter cipherView: The cipher to generate the TOTP from.
    private func copyTotpIfNeeded(cipherView: CipherView) async {
        do {
            let disableAutoTotpCopy = try await services.vaultRepository.getDisableAutoTotpCopy()
            let accountHasPremium = await services.vaultRepository.doesActiveAccountHavePremium()

            if !disableAutoTotpCopy, let totp = cipherView.login?.totp,
               cipherView.organizationUseTotp || accountHasPremium {
                let key = TOTPKeyModel(authenticatorKey: totp)
                if let codeModel = try await services.vaultRepository.refreshTOTPCode(for: key).codeModel {
                    services.pasteboardService.copy(codeModel.code)
                }
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Handles autofill for a cipher after the master password reprompt has been confirmed, if it's
    /// required by the cipher.
    ///
    /// - Parameters
    ///   - cipherView: The `CipherView` to use for autofill.
    ///   - showToast: A closure that when called will display a toast to the user.
    ///
    private func handleCipherForAutofillAfterRepromptIfRequired(
        cipherListView: CipherListView,
        showToast: @escaping (String) -> Void,
    ) async {
        do {
            guard let cipherId = cipherListView.id,
                  let cipherView = try await services.vaultRepository.fetchCipher(withId: cipherId) else {
                services.errorReporter.log(
                    error: BitwardenError.dataError(
                        "No cipher found on AutofillHelper handleCipherForAutofillAfterRepromptIfRequired.",
                    ),
                )
                coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
                return
            }

            let username = cipherView.login?.username ?? ""
            let password = cipherView.login?.password ?? ""

            let canStandardAutofill = (appExtensionDelegate?.canAutofill ?? false)
                && !username.isEmpty
                && !password.isEmpty

            let savedMapping = await loadAutofillAssistMapping()

            guard canStandardAutofill
                || (savedMapping != nil && (!username.isEmpty || !password.isEmpty)) else {
                await handleMissingValueForAutofill(cipherView: cipherView, showToast: showToast)
                return
            }

            await copyTotpIfNeeded(cipherView: cipherView)

            let fields: [(String, String)]? = cipherView.fields?.compactMap { field in
                guard let name = field.name, let value = field.value else { return nil }
                return (name, value)
            }

            await services.eventService.collect(
                eventType: .cipherClientAutofilled,
                cipherId: cipherView.id,
            )

            let (usernameOpId, passwordOpId) = resolveAutofillAssistOpIds(from: savedMapping)
            appExtensionDelegate?.completeAutofillRequest(
                username: username,
                password: password,
                fields: fields,
                usernameOpId: usernameOpId,
                passwordOpId: passwordOpId,
            )
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    /// Loads a saved Autofill Assist mapping for the current page URL, if one exists.
    ///
    private func loadAutofillAssistMapping() async -> AutofillAssistMapping? {
        guard let uri = appExtensionDelegate?.uri,
              let host = URL(string: uri)?.host,
              let userId = try? await services.stateService.getActiveAccountId() else {
            return nil
        }
        return try? await services.autofillAssistService.getMapping(forHost: host, userId: userId)
    }

    /// Resolves a saved mapping to `(usernameOpId, passwordOpId)` using the current page fields.
    ///
    private func resolveAutofillAssistOpIds(
        from mapping: AutofillAssistMapping?,
    ) -> (String?, String?) {
        guard let mapping, let pageDetails = appExtensionDelegate?.pageDetails else {
            return (nil, nil)
        }
        let resolved = services.autofillAssistService.resolveOpIds(
            mapping: mapping,
            fields: pageDetails.fields,
        )
        return (resolved.usernameOpId, resolved.passwordOpId)
    }

    /// Handles the case where the username or password is missing for the cipher which prevents it
    /// from being used for autofill.
    ///
    /// - Parameters
    ///   - cipherView: The `CipherView` to use for autofill.
    ///   - showToast: A closure that when called will display a toast to the user.
    ///
    private func handleMissingValueForAutofill(cipherView: CipherView, showToast: @escaping (String) -> Void) async {
        guard let login = cipherView.login,
              !login.username.isEmptyOrNil ||
              !login.password.isEmptyOrNil ||
              !login.totp.isEmptyOrNil
        else {
            coordinator.showAlert(.defaultAlert(title: Localizations.noUsernamePasswordConfigured))
            return
        }

        let alert = Alert(title: cipherView.name, message: nil, preferredStyle: .actionSheet)

        if let username = login.username, !username.isEmpty {
            alert.add(AlertAction(title: Localizations.copyUsername, style: .default, handler: { _ in
                self.services.pasteboardService.copy(username)
                showToast(Localizations.valueHasBeenCopied(Localizations.username))
            }))
        }

        if let password = login.password, !password.isEmpty {
            alert.add(AlertAction(title: Localizations.copyPassword, style: .default, handler: { _ in
                self.services.pasteboardService.copy(password)
                showToast(Localizations.valueHasBeenCopied(Localizations.password))
            }))
        }

        do {
            if let totp = try await services.vaultRepository.getTOTPKeyIfAllowedToCopy(cipher: cipherView) {
                alert.add(AlertAction(title: Localizations.copyTotp, style: .default) { _ in
                    do {
                        let key = TOTPKeyModel(authenticatorKey: totp)
                        let response = try await self.services.vaultRepository.refreshTOTPCode(for: key)
                        if let code = response.codeModel?.code {
                            self.services.pasteboardService.copy(code)
                            showToast(Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp))
                        } else {
                            self.coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
                        }
                    } catch {
                        self.coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
                        self.services.errorReporter.log(error: error)
                    }
                })
            }
        } catch {
            services.errorReporter.log(error: error)
        }

        alert.add(AlertAction(title: Localizations.cancel, style: .cancel))

        coordinator.showAlert(alert)
    }

    /// Presents the master password reprompt alert and calls the completion handler when the user's
    /// master password has been confirmed.
    ///
    /// - Parameter completion: A completion handler that is called when the user's master password
    ///     has been confirmed.
    ///
    private func presentMasterPasswordRepromptAlert(completion: @escaping () async -> Void) {
        let alert = Alert.masterPasswordPrompt { [weak self] password in
            guard let self else { return }

            do {
                let isValid = try await services.authRepository.validatePassword(password)
                guard isValid else {
                    coordinator.showAlert(.defaultAlert(title: Localizations.invalidMasterPassword))
                    return
                }
                await completion()
            } catch {
                services.errorReporter.log(error: error)
            }
        }
        coordinator.showAlert(alert)
    }
}
